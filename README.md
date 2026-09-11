### AI Usage Disclosure

This project is being developed with assistance from OpenAI Codex (GPT-6),
including implementation guidance, configuration review, troubleshooting
and documentation drafting.

Development follows an incremental workflow in which proposed changes
are reviewed and discussed before proceeding.

### Consulted Documentation
[Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html#authenticated-controllers)
[Active Record Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html#aliases-for-after-commit)
[Classic to Zeitwer](https://edgeguides.rubyonrails.org/classic_to_zeitwerk_howto.html)
[Solid Queue](https://github.com/rails/solid_queue#concurrency-controls)
[SimpleCov](https://github.com/simplecov-ruby/simplecov?tab=readme-ov-file)
[GitHub Artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data)
[Daisy UI](https://daisyui.com/docs/use/)
[Turbo](https://turbo.hotwired.dev/reference/drive)
[CodeQl](https://codeql.github.com/codeql-query-help/ruby/rb-clear-text-storage-sensitive-data/)
[Mailcatcher](https://mailcatcher.me/)

# Umanni User Management

The technical challenge is described in [CHALLENGE.md](CHALLENGE.md).

## Current status

Implemented features include native Rails authentication, password
reset, public registration and role based access control.

Members can view and edit their own profile, upload an avatar and
delete the account.

Administrators can manage users through a paginated interface and
view live dashboard counters grouped by role.

CSV and XLSX imports run asynchronously through Solid Queue, with
live progress updates and row-level error reporting.

Browser tests cover registration, authentication, profile management,
administrative user management and automatic import progress updates.

A narrow-screen test checks administrative navigation and horizontal
page overflow. Tests run with Selenium and headless Chrome.

Final delivery documentation and production setup verification
are still pending.

## Stack

- Ruby 4.0.6, managed with rbenv
- Rails 8.1.3.1
- PostgreSQL 17
- Hotwire: Turbo and Stimulus, with Importmap
- Tailwind CSS, daisyUI and Propshaft
- Solid Queue and Solid Cable
- Minitest, Capybara and Selenium
- RuboCop, Brakeman and Bundler Audit

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

## Create the first administrator

The seed reads these environment variables:

- `ADMIN_FULL_NAME`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD` — at least 12 characters.

On macOS with zsh:

    export ADMIN_FULL_NAME="Administrator"
    export ADMIN_EMAIL="admin@example.com"
    read -s "ADMIN_PASSWORD?Initial password: "
    export ADMIN_PASSWORD

    bin/rails db:seed

    unset ADMIN_PASSWORD ADMIN_EMAIL ADMIN_FULL_NAME

Sign in at `/session/new` using the supplied email and password.

Running the seed again preserves an existing administrator's name,
password and other account details. If the email belongs to a member,
the seed fails without modifying that account.

When all three variables are absent, administrator creation is skipped.
Partial configuration raises an error.

## Run locally

```sh
bin/dev
```

This starts the Rails server, Tailwind watcher and Solid Queue workers.

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
revocation and user validations.

Line coverage is measured with SimpleCov, including merged results
from parallel test workers. The CI test job requires at least 90%
line coverage and uploads the HTML report as `coverage-report`.

To generate the report locally:
```sh
  RAILS_ENV=test COVERAGE=1 bin/rails test
  bundle exec simplecov open
```

## Authentication

Authentication uses the Rails authentication generator and BCrypt.

Email are normalized and validated. New passwords require at
least 12 characters.

Successful password resets revoke all existing database sessions
for the user.

Visitors can register at `/registration/new` with their full name,
email, password and password confirmation. New accounts always
receive the member role and are signed in automatically.

Password reset emails are queued through Solid Queue.

## Email delivery

Development emails are captured locally with MailCatcher and are
not delivered to real inboxes.

Install and start MailCatcher separately from the application bundle:
```sh
  gem install mailcatcher
  mailcatcher
```

Start the application and background workers:
```sh
  bin/dev
```

Open http://127.0.0.1:1080 to view captured messages.
Request a password reset for an existing account and follow the link
in the captured email.

Development SMTP uses 127.0.0.1:1025 without authentication or TLS.
The test environment uses the test delivery adapter and does not
require MailCatcher.

Production SMTP is configured through these environment variables:

- SMTP_ADDRESS
- SMTP_PORT (defaults to 587)
- SMTP_USERNAME
- SMTP_PASSWORD
- MAIL_FROM
- APP_HOST — public application hostname, without a protocol
  (for example, app.example.com).
- APP_PROTOCOL — defaults to https.

Production SMTP requires STARTTLS. Credentials must be supplied
through the deployment environment and must not be committed.

The password reset flow was validated locally through MailCatcher.
Delivery through an external production provider has not been verified.

## Spreadsheet imports

Admins can upload CSV or XLSX files from the dashboard.

- Maximum file size: 5 MB.
- Maximum data rows: 5,000.
- XLSX imports use the first page.
- Required headers: `full_name`, `email`.
- Optional header: `role` (`member` or `admin`); defaults to `member`.
- Empty rows are ignored.
- Existing emails and invalid user data produce row errors.
- Valid rows continue to be processed when another row fails.
- Imported users recive random passwords and can use password reset
  to create a new one. Email delivery must be configured for this flow.

Solid Queue processes imports in the background. Keep the worker running
with `bin/jobs`; `bin/dev` starts it in development.

The import page updates through Solid Cable and displays progress and
the first 100 row errors. All row errors remain stored in the database.
A completed import may contain rejected rows.

Committed rows are skipped when the same import job is running again.
Unexpected failures are recorded in Solid Queue; automatic retries
are not configured.

While an import is pending or processing, the page also checks the
status every three seconds to recover updates missed before the
live connection was established. Checks stop after completion or failure.

## Docker and CI

The production Dockerfile uses multiple stages and starts Rails
through Thruster.

```sh
docker build -t umanni .
```

The GitHub Actions Docker job builds the image, starts it against
a temporary PostgreSQL 17 service and checks for HTTP 200 at `/up`.

The container entrypoint prepares the production databases before
starting the server. The CI check supplies separate connection URLs
for the primary, queue and cable databases.

The production Docker image was built and its `/up` endpoint
returned HTTP 200 in GitHub Actions.

## Configuration notes

- JSON is restricted to the 2.x series because Active Support 8.1.3.1
  passes positional options incompatible with JSON 3.
- Credentials keys and local environment files are excluded from Git.
- Avatars accept JPEG and PNG files up to 5 MB.
- Avatar downloads require authentication. 
- Members can access their own avatar; admins can upload, view, 
  replace and remove avatars through the dashboard.
- Default Active Storage routes are disabled.
- Files are stored locally. Production deployments must persist
  `/rails/storage` or configure an external storage service.
- Existing users must have their full names populated before applying
  the migration that makes full names mandatory.
