class String
  def safe_quote
    self.gsub(/['"]/, '\\\"')
  end
end
