To run the tests, first ensure that all of the required gems are installed.

`bundle`

Next, install the support gems for all test environments.

`bundle exec appraisal install`

Run all of the tests.

`bundle exec appraisal rake test`

Run a subset of the tests (focus a specific version of ActiveRecord).

`bundle exec appraisal activerecord_4.2.0 rake test`
