#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

def display_usage()
  puts "Usage: \n" \
  "$ ruby main.rb algo inputs \n" \
  "Example: \n" \
  "ruby main.rb fifo inputs/test1.txt \n" \
  "Where algo can be: \"fifo\", \"first_fit\", \"edf\", \"round_robin\", \"wavefront\", \"cpm\" \n" \
  "and the inputs is a .txt file (see inputs folders) \n" \
  "Exiting..."
  exit(0)
end

if ARGV.include? "--help" or ARGV[0].nil? || ARGV[1].nil?
  display_usage()
end

# deactivate verbose logs
unless ARGV.include? "--silent"
  puts "Use --silent to run it silently \n" \
  "Use --help to display the help \n" \
  "The output is silenced when the system is empty"
end

# Logs
def display_result(dc)
  sumup = "\n--------------------------------------------\n" \
  "        *** Sum up of the datacenter ***\n" \
  "- Job's id arrival:\n" \
  "#{schedule_with_periodicity().map{ |j| j.id }}\n" \
  "- Power capacity: #{dc.power_cap}\n" \
  "- Total power used: #{dc.power_used.reduce(0, :+)} / #{dc.energy_cap} available\n" \
  "- Makespan: #{dc.timestep-1} unit of time\n" \
  "- Deadline missed: #{dc.deadline_missed}\n" \
  "- Repeat: #{dc.repeat} times\n" \
  "--------------------------------------------\n"
  unless ARGV.include? "--silent"
    puts sumup
  end
  File.open('outputs/sumup.txt' , 'w') do |file|
    file.write(sumup)
  end
end

# Map the jobs in an array
# @return an array of Job objects
def schedule_with_periodicity(jobs=parse_jobs())
  # see parse_input.rb
  #jobs = parse_jobs()
  jobs.each do |job|
    unless job.periodicity == 0 or jobs.map{ |j| j.id }.count(job.id) > 1
      # duplicate periodic job and fix arrival and relative_deadline
      periodic_job = job.dup
      periodic_job.arrival = job.periodicity + job.arrival
      periodic_job.relative_deadline = periodic_job.arrival + periodic_job.deadline
      # insert it at the good arrival place in the array of jobs
      i = 0
      jobs.map do |j|
        if periodic_job.arrival > jobs[i].arrival and
          (jobs[i+1].nil? or periodic_job.arrival < jobs[i+1].arrival)
          jobs.insert(i + 1, periodic_job)
          break
        end
        i += 1
      end
    end
  end
  return jobs
end

# Write the results on a file for plotter to read it
def write_scheduling_to_file(servers)
  filename = "outputs/results.txt"
  File.open(filename, "w") do |file|
    # header of the file
    file.write("#jobid serverid start end\n")
    file_content = Array.new
    # we read the queue of each server
    servers.each do |server|
      server.queue.each do |job|
        file_content << "#{job.id} #{server.id} #{job.start} #{job.end}"
      end
    end
    # sort by ascending job id
    file_content.sort_by! { |line| line.split(' ').first }
    file_content.each do |line|
      if line.split(' ')[3].to_f < 20
        file.write(line + "\n")
      else
        # to keep the graph compact
        # if the periodicity is too high, we comment it for python
        file.write("#arrival > 20, exclude from graph plot\n#" + line + "\n")
      end
    end
  end
end

def write_power_to_file(powers)
  File.open("outputs/powers.txt", "w") do |file|
    file.write(powers.to_s[1..-2])
  end
end

# this should run the python script automaticaly 
# at the end of the computation according to the OS
# (Linux only has been tested - experimental)
def display_graph()
  begin
    case
      when RUBY_PLATFORM.include?("linux")
        exec("python3 src/plotter/plotter.py outputs/results.txt")
        unless ARGV.include? "--silent"
          exec("xdg-open 'outputs/task_scheduling.png'")
          exec("xdg-open 'outputs/power_consumption.png'")
        end
      when RUBY_PLATFORM.include?("darwin")
        exec("python3 src/plotter/plotter.py outputs/results.txt")
        unless ARGV.include? "--silent"
          exec("xdg-open 'outputs/task_scheduling.png'")
          exec("open 'outputs/power_consumption.png'")
        end
      when RUBY_PLATFORM.include?("mswin")
        exec("cmd /c python3 src/plotter/plotter.py outputs/results.txt")
        unless ARGV.include? "--silent"
          exec("xdg-open 'outputs/task_scheduling.png'")
          exec("cmd /c \"start 'outputs/power_consumption.png'\"")
        end
    end
  rescue
    print("An error occured while executing the plotter.")
  end
end