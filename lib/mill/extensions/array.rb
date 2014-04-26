class Array

  def insert_after(element, object)
    insert(index(element) + 1, object)
  end

end