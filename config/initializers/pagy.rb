Pagy::DEFAULT[:items] = 50  # Items per page
Pagy::DEFAULT[:limit] = 50  # Add this line to match items
Pagy::DEFAULT[:overflow] = :last_page  # Handle overflows


# Load Dutch locale
Pagy::I18n.load(locale: 'nl')