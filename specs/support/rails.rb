module Rails

  def self.root
    File.expand_path File.join(__FILE__, "..", "app")
  end

  def self.env
    'development'
  end

end
