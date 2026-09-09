### AI Usage Disclosure

This project is being developed with assistance from OpenAI Codex (GPT-6),
including implementation guidance, configuration review, troubleshooting
and documentation drafting.

Development follows an incremental workflow in which proposed changes
are reviewed and discussed before proceeding.

# Umanni User Management

The technical challenge is described in [CHALLENGE.md](CHALLENGE.md).

## Current status

Initial setup and native Rails authentication are implemented,
including sign-in, sign-out, and password reset.

Registration, user roles, profiles, and administrative features
have not been implemented yet.

## Stack

- Ruby 4.0.6, managed with rbenv
- Rails 8.1.3.1
- PostgreSQL 17
- Hotwire: Turbo and Stimulus, with Importmap
- Tailwind CSS and Propshaft
- Solid Queue and Solid Cable
- Minitest, Capybara, and Selenium
- RuboCop, Brakeman, and Bundler Audit

Redis is not required in this project.

## Local setup

Install rbenv with ruby-build and start PostgreSQL 17.

From the project directory:

```sh
rbenv install -s 4.0.6
rbenv local 4.0.6
bundle install
gem install foreman
rbenv rehash
bin/rails db:prepare
RAILS_ENV=test bin/rails db:prepare
```

The default local database connection uses a Unix socket and a
PostgreSQL role matching the operating-system username. This role
must be allowed to create databases.

Development uses three databases:

- `umanni_development`
- `umanni_development_queue`
- `umanni_development_cable`

Tests use `umanni_test`.

## Run locally

```sh
bin/dev
```

This starts the Rails server, Tailwind watcher, and Solid Queue workers.

Open http://localhost:3000.
The health endpoint is available at http://localhost:3000/up.

## Checks

```sh
bin/rails test
bin/rails test:system
bin/rubocop
bin/rails zeitwerk:check
bin/brakeman
bin/bundler-audit
bin/importmap audit
```

The test suite covers authentication, password reset, session
revocation, and user validations. Code coverage is not measured yet.

## Authentication

Authentication uses the Rails authentication generator and BCrypt.

Email are normalized and validated. New passwords require at
least 12 characters.

Successful password resets revoke all existing database sessions
for the user.

Registration is not implemented yet. Development users can be
created through `bin/rails console`.

Password reset emails are queued through Solid Queue. SMTP delivery
has not been configured or validated yet.

## Docker and CI

The production Dockerfile uses multiple stages and starts Rails
through Thruster.

```sh
docker build -t umanni .
```

The GitHub Actions Docker job builds the image, starts it against
a temporary PostgreSQL 17 service, and checks for HTTP 200 at `/up`.

The container entrypoint prepares the production databases before
starting the server. The CI check supplies separate connection URLs
for the primary, queue, and cable databases.

The production Docker image was built and its `/up` endpoint
returned HTTP 200 in GitHub Actions.

## Configuration notes

- JSON is restricted to the 2.x series because Active Support 8.1.3.1
  passes positional options incompatible with JSON 3.
- Credentials keys and local environment files are excluded from Git.
- No seed data is defined yet.
