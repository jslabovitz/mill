class Path

  def hidden?
    basename.to_s[0] == '.'
  end

end