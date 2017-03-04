class Utils
  COLUMN_WIDTH = 30

  def self.podspec_version(file = 'SwiftGen')
    JSON.parse(`bundle exec pod ipc spec SwiftGen/#{file}.podspec`)["version"]
  end

  def self.plist_version
    Plist::parse_xml('SwiftGen/Sources/Info.plist')['CFBundleVersion']
  end

  def self.log_info(label, msg)
    puts "#{label.ljust(30)} 👉  #{msg}"
  end

  def self.log_result(result, label, error_msg)
    if result
      puts "#{label.ljust(COLUMN_WIDTH)} ✅"
    else
      puts "#{label.ljust(COLUMN_WIDTH)} ❌  - #{error_msg}"
    end
    result
  end
end
