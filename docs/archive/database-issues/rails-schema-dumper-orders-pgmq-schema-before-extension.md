---
title: "Fix Rails Schema Load Failure by Ordering the pgmq Schema Before Its Extension"
category: database-issues
problem_type: database_issue
component: "Active Record PostgreSQL SchemaDumper"
framework: "Rails 8.1.3"
database: PostgreSQL
tags:
  - rails-8.1
  - postgresql
  - pgmq
  - schema-dumper
  - schema.rb
  - pg-invalid-schema-name
  - db-test-prepare
  - schema-qualified-extension
date: 2026-07-11
---

# Fix Rails Schema Load Failure by Ordering the pgmq Schema Before Its Extension

## Problem

A migrated development database worked, but creating a clean test database failed:

```text
PG::InvalidSchemaName: ERROR: schema "pgmq" does not exist
```

`bin/rails db:test:prepare` and `db:schema:load` both failed at this line in `db/schema.rb`:

```ruby
enable_extension "pgmq.pgmq"
```

The schema file did not first contain `create_schema "pgmq"`.

## Root Cause

Rails dumps PostgreSQL schemas and extensions through different paths. Extensions are collected globally, so an extension installed outside `public` is serialized with its schema as `pgmq.pgmq`. Loading that line becomes `CREATE EXTENSION ... SCHEMA pgmq`.

Schemas are selected through `ActiveRecord.dump_schemas`, which defaults to the connection's schema search path. Because the application search path does not include `pgmq`, Rails omitted the namespace that the qualified extension required. The generated Ruby schema was therefore not replayable on a clean database.

The pgbus migration's `:auto` native-extension/embedded fallback does not help here because `schema.rb` replay does not run the migration.

## Solution

Add a targeted PostgreSQL schema dumper extension in `config/initializers/schema_dump.rb`:

```ruby
# frozen_string_literal: true

# The pgmq extension is installed into its own schema. Rails records the
# qualified extension but does not otherwise dump that extension-owned schema.
module PgmqSchemaDump
  private

  def schemas(stream)
    stream.puts %(  create_schema "pgmq"\n\n)
    super
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(PgmqSchemaDump)
end
```

Rails already writes schemas before extensions. The override adds only the missing namespace, producing:

```ruby
create_schema "pgmq"

enable_extension "pg_catalog.plpgsql"
enable_extension "pgmq.pgmq"
```

This keeps PostgreSQL responsible for the extension-owned functions and tables instead of making Rails dump those internal objects.

## Rejected Alternatives

- A manual `CREATE SCHEMA pgmq` is erased by database purge/drop and does not help CI or new developers.
- Editing `db/schema.rb` directly is overwritten by the next schema dump.
- Adding `pgmq` to `ActiveRecord.dump_schemas` also dumps extension-owned queue/archive tables. Schema replay then attempts to replace objects required by the extension and fails with dependent-object errors.
- Switching to `structure.sql` can represent the PostgreSQL structure, but changes the project's schema workflow and is broader than this targeted fix.

## Verification

Regenerate the schema and prove it loads into a completely fresh test database:

```bash
bin/rails db:schema:dump
RAILS_ENV=test bin/rails db:drop db:create
RAILS_ENV=test bin/rails db:schema:load
bin/rails test
```

The verified run loaded the fresh schema and completed 27 tests with no failures. `db:test:prepare` should also remain part of clean-database CI coverage.

## Prevention

- In CI, load `db/schema.rb` into a fresh PostgreSQL database rather than relying only on a reused or migrated database.
- Assert that `create_schema "pgmq"` occurs before `enable_extension "pgmq.pgmq"` after every schema dump.
- On Rails upgrades, review the private `PostgreSQL::SchemaDumper#schemas` signature and the schema/extension dump order. Remove this override when upstream behavior makes it unnecessary.
- Do not broaden the patch to the whole schema dumper or silently rescue schema-load failures.

## Limitations

The Ruby schema still assumes the native `pgmq` extension is available on the target PostgreSQL server. The migration's embedded fallback cannot reconstruct its functions during `schema.rb` replay. Queue tables created dynamically by pgmq are intentionally absent and are recreated idempotently by pgbus startup.

The override is unconditional. If `pgmq` is later added to the application's schema search path or Rails starts dumping extension schemas automatically, guard or remove it to avoid duplicate `create_schema` statements.
