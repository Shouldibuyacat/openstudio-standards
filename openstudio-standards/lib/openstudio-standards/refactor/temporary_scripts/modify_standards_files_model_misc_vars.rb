require 'openstudio'
require 'json'

refactor_standards_dir = '../standards'

def class_name(lines)
  name = 'TODO_CLASS_NAME'
  lines.each do |line|
    m = line.match(/def\s\w*\((\w*)/) 
    if m
      name = m[1]
      break
    end
  end
  return name
end

# Revise the calls to model to get the model from the object in question
Dir.glob("#{refactor_standards_dir}/*.rb").each do |file_path|
  file_name = File.basename(file_path)
  puts ''
  puts file_name
  
  lines = File.readlines(file_path)
  c_name = class_name(lines)
  c_name = OpenStudio.toUnderscoreCase(c_name)
  puts c_name

  new_lines = []
  lines.each do |line|
    new_line = 'UNDEFINED'
    if line.strip[0] == '#' # Skip comment lines
      new_lines << line
      next
    elsif line.include?('#{name}')
      new_line = line.gsub('#{name}', '#{' + c_name + '.name}')
      new_lines << new_line
      puts "#{line} => #{new_line}"
    elsif line.include?('self')
      new_line = line.gsub('self', c_name)
      new_lines << new_line
      puts "#{line} => #{new_line}"
    else
      new_lines << line
    end
  end
  
  # Write the revised file
  File.open("#{file_path}", 'w') do |file|
    new_lines.each do |line|
      file.puts(line)
    end
  end
  
end