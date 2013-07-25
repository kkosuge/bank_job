class String
  def to_integer
    self.gsub(',','').to_i
  end
end
