module Mill

  ConfigFileName = 'mill.yaml'

  BaseConfig = Simple::Config.define(
    dir: { default: '.', converter: :path },
    input_dir: { default: 'content', converter: :path },
    output_dir: { default: 'public_html', converter: :path },
    code_dir: { default: 'code', converter: :path },
    site_uri: { default: 'http://localhost', converter: :uri },
    site_rsync: nil,
    site_title: nil,
    site_email: nil,
    site_twitter: { converter: :uri },
    site_instagram: { converter: :uri },
    site_postal: nil,
    site_phone: nil,
    site_control_date: { converter: :date },
    html_version: { default: :html5, converter: :symbol },
    make_error: true,
    make_feed: true,
    make_sitemap: true,
    make_robots: true,
    allow_robots: true,
  )

end