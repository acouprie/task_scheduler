#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

# usage example: ruby main.rb fifo inputs/test1.txt

splitted_path = ARGV[1].split("/")
@input_path = splitted_path.take(splitted_path.length() - 1).join()

# read the input file, extract some values return a hash of values
def parse_input()
  values = {}
  File.open(ARGV[1], 'r') do |file|
    # read file line by line
    file.each do |line|
      # only keep lines with "=" inside
      if line.include? "="
        # split by words (and remove char ")
        splitted = line.delete("\"").split(" ")
        # store values into a hash
        values[splitted[0]] = splitted[-1]
      end
    end
  end
  return values
end

@data = parse_input()

# read the job file
# return an array of jobs object
def parse_jobs(job_file=nil)
  jobs = []
  if job_file.nil?
    job_file = @input_path + "/" + @data["job_file"]
  end
  File.open(job_file, 'r') do |file|
    # read the file line by line
    file.each do |line|
      # skip commented line
      next if line.start_with?('#')
      elements = line.split(" ").map{|element| element.to_i}
      jobs << Job.new(
        elements[0],
        elements[1],
        elements[2],
        elements[3],
        elements[4]
      )
    end
  end
  return jobs
end

# read the dependancies file
# return an array of dependancies
def parse_dependencies()
  dependencies = []
  dependencies_file = @input_path + "/" + @data["dependency_file"]
  File.open(dependencies_file, 'r') do |file|
    # read the file line by line
    file.each do |line|
      # skip commented line
      next if line.start_with?('#') or !line.include?(" - ")
      elements = line.split(" - ").map{|element| element.to_i}
      dependencies << [elements[0], elements[1]]
    end
  end
  return dependencies
end

# read the server file
# return an array of servers object
def parse_servers(server_file=nil)
  servers = []
  if server_file.nil?
    server_file = @input_path + "/" + @data["server_file"]
  end
  File.open(server_file, 'r') do |file|
    # read the file line by line
    file.each do |line|
      # skip commented line
      next if line.start_with?('#')
      frequencies = line[/\(.*?\)/][1..-2].split(" ")
      elements = line.split(" ").map{|element| element.to_i}
      servers << Server.new(elements[0],elements[1],frequencies)
    end
  end
  return servers
end
