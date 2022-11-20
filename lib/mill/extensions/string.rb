class String

  def to_html
    Mill::Resource::Text.string_to_html(self)
  end

end