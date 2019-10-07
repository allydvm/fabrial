# frozen_string_literal: true

# TODO: properly hook up parent associations for pre-created objects passed in
# TODO: Split out the default practice and sync client into its own file

# TODO: fix this rubocop instead of disabling
# rubocop:disable Metrics/ModuleLength - this will have some things factored out
# for the generic stuff, then this disable can be removed
module Fabrial::Fabricate
  # Make expects a nested hash of type => data or [data]
  def fabricate(objects)
    # TODO: Raise error if mixing array and hash return styles

    # If a return object(s) wasn't specified, default to returning the first
    # object.
    unless contains_return? objects
      ret = objects.values.find do |v|
        v.is_a?(Hash) || (v.is_a?(Array) && !v.empty?)
      end
      if ret
        ret = ret.first if ret.is_a? Array
        ret[:RETURN] = true
      end
    end
    objects = add_defaults objects
    ancestors = {}
    returns = make_types objects, ancestors

    # If returns is made up of pairs, return a hash.
    if returns.first.is_a? Array
      returns.to_h
    else
      returns.length <= 1 ? returns.first : returns
    end
  end

  private

  def contains_return?(objects)
    return false unless objects.is_a? Hash

    objects.key?(:RETURN) || objects.any? do |_k, v|
      v.is_a?(Hash) && contains_return?(v) ||
        v.is_a?(Array) && v.any?(&method(:contains_return?))
    end
  end

  # Setup default source and practice if not provided
  def add_defaults(objects)
    return objects if objects.delete :NO_DEFAULTS

    unless %i[source sources].any? { |k| objects.key? k }
      objects = { source: default_source.merge(objects) }
    end

    # We can only make a default practice if we are dealing with a single sync
    # client.
    source = objects[:source]
    if source.is_a?(Hash)
      unless %i[practice practices].any? { |p| source.key? p }
        children = extract_child_records Practice, source
        source[:practice] = default_practice.merge children
      end
    end

    objects
  end

  # return_skip_levels allows us to skip created default practices and
  # sources when choosing an object to return.
  def make_types(objects, ancestors)
    returns = []
    objects.each do |type, data|
      klass = get_class(type)
      returns.concat make_type klass, data, ancestors
    end
    returns
  end

  def make_type(klass, data_list, ancestors)
    returns = []

    # TODO: may need a hook here
    # ::Maker.next_bank klass # Needed if we aren't in test

    associations = collect_associations(klass, ancestors)
    Array.wrap(data_list).each do |data|
      should_return = data.delete :RETURN
      children = extract_child_records klass, data
      add_implicit_owner klass, ancestors, children
      object = make_object klass, data, associations

      # Make sure new object is added as last item of ancestor hash
      # collect_associations expects this in order to hook up polymorphic fields
      next_ancestors = ancestors.dup.except klass
      next_ancestors[klass] = object

      if should_return
        # If `RETURN` holds a value, use it as the key.
        returns << if should_return == true
                     object
                   else
                     [should_return, object]
                   end
      end

      returns.concat make_types children, next_ancestors
    end
    returns
  end

  def make_object(klass, data, associations)
    # Check for already created object
    return data[:object] if data[:object]

    type_col = klass.inheritance_column.try :to_sym
    type = data.delete(type_col).try :safe_constantize
    type ||= klass
    create type, data.reverse_merge(associations)
  end

  def collect_associations(klass, ancestors)
    associations = collect_parents(klass, ancestors)
    if (p = polymorphic(klass))
      associations[p] = ancestors.values.last
    end
    associations
  end

  def extract_child_records(klass, data)
    children = data.select do |type, v|
      # Must have nested data
      [Array, Hash].any? { |c| v.is_a? c } &&
        # Must be a class that we can instantiate
        get_class(type) &&

        # Even if it has the same name as a Model in the system, if it is also
        # the name of a column in the table, assume the data is for a serialzed
        # field and not a nested relation.  Ex: Requests have a serialized field
        # called content and there is also a Content model in the system.
        (
          # If they are using a class as the key, then always choose the class
          # over the field.
          type.is_a?(Class) ||

            !column_names(klass).include?(type.to_s)
        )
    end
    data.extract!(*children.keys)
  end

  def column_names(klass)
    klass.column_names

    # our project uses
    # klass.column_names_including_stored
  end

  def add_implicit_owner(klass, ancestors, children)
    {
      [Client, Patient] => Owner,
      [Enterprise, Practice] => EnterpriseMembership,
    }. each do |connected, connector|
      next unless (connected.delete klass) && (ancestors.key? connected[0])

      unless children.key? connector.name.demodulize.underscore.to_sym
        children.reverse_merge! connector => {}
      end
    end
  end

  def collect_parents(klass, ancestors)
    associations = klass.reflect_on_all_associations
    polymorphics = associations.select(&:polymorphic?)
    associations
      .select do |a|
        (!a.collection? || a.macro == :has_and_belongs_to_many) &&
          !a.polymorphic? &&

          # This is to throw out specified versions of polymorphic associations.
          # Ex: Alert has a polymorphic association called `alertable` and two
          # other associations, `alertable_patient` and `alertable_client` that
          # allow joining to specific tables.  These specified associations
          # should be skipped.
          polymorphics.none? do |other|
            other != a && other.name.to_s == a.name.to_s.split('_').first
          end
      end
      .select { |a| ancestors.key? a.klass } # Find ancestors that match
      .map do |a| # Create data hash
        if a.macro == :has_and_belongs_to_many
          [a.name, [ancestors[a.klass]]]
        else
          [a.name, ancestors[a.klass]]
        end
      end.to_h
  end

  def polymorphic(klass)
    klass.reflect_on_all_associations
      .select(&:polymorphic?)
      .map { |a| a.class_name.underscore.to_sym }[0]
  end

  def get_class(type)
    return type if type.is_a? Class

    type.to_s.classify.safe_constantize ||
      type.to_s.classify.pluralize.safe_constantize
  end

  DEFAULT_SOURCE_ID = -123
  public_constant :DEFAULT_SOURCE_ID
  def default_source
    c = Source.find_by id: DEFAULT_SOURCE_ID
    c ? { object: c } : { id: DEFAULT_SOURCE_ID }
  end

  DEFAULT_PRACTICE_ID = -456
  public_constant :DEFAULT_PRACTICE_ID
  def default_practice
    p = Practice.find_by id: DEFAULT_PRACTICE_ID
    p ? { object: p } : { id: DEFAULT_PRACTICE_ID }
  end
end
# rubocop:enable Metrics/ModuleLength
