# Litesearch creates its tokenizer-dependent virtual tables at runtime.
# A fresh database connection cannot load :simple during schema:load.
ActiveRecord::SchemaDumper.ignore_tables += [ /\Aknowledge_articles_search_idx/ ]
