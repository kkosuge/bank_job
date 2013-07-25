class Fixnum
  def humanize
    parts = self.to_s.split('.')
    "#{parts[0].gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")}円"
  end
end
