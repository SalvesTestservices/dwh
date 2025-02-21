PgSearch.multisearch_options = {
  using: {
    tsearch: {
      prefix: true
    }
  }
}

PgSearch::Document.establish_connection :dwh