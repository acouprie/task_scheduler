#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier
require "./src/datacenter.rb"
require "./src/server.rb"
require "./src/job.rb"
require "./src/parse_input.rb"
require "./src/helper.rb"

# usage example: ruby main.rb fifo inputs/test2.txt

# the followings results have been validated by manual computation
fifo_1_results =
"#jobid serverid start end\n" \
"0 0 0 3.3\n" \
"1 1 0 5.0\n" \
"2 2 0 1.7\n" \
"3 3 0 2.5\n" \
"4 2 2 3.7\n" \
"5 3 3 5.5\n" \
"6 0 4 7.3\n" \
"7 2 4 5.7\n" \
"8 1 5 10.0\n"

first_fit_results = 
"#jobid serverid start end\n" \
"0 2 0 1.7\n" \
"1 3 0 2.5\n" \
"2 0 0 3.3\n" \
"3 1 0 5.0\n" \
"4 2 2 3.7\n" \
"5 3 3 5.5\n" \
"6 2 4 5.7\n" \
"7 0 4 7.3\n" \
"8 1 5 10.0\n"

edf_results =
"#jobid serverid start end\n" \
"0 2 0 1.7\n" \
"1 1 0 5.0\n" \
"2 2 4 5.7\n" \
"3 3 0 2.5\n" \
"4 2 2 3.7\n" \
"5 0 4 7.3\n" \
"6 0 0 3.3\n" \
"7 3 3 5.5\n" \
"8 1 5 10.0\n"

edf_result_premption =
"#jobid serverid start end\n" \
"0 2 0 1.7\n" \
"1 3 0 2.5\n" \
"2 0 0 3.3\n" \
"3 1 0 1\n" \
"3 2 2 3.3\n" \
"4 1 1 3.0\n"

# check is the output file is equal to the constant
def validation(valid)
  results = ""
  File.open("outputs/results.txt", "r") do |file|
    results = file.read()
  end
  #p results
  #p valid
  if results == valid
    puts "."
    return true
  else
    puts "E"
    return false
  end
end

# simple fifo verification
def test_fifo_without_energy_constraint(validation)
  datacenter = Datacenter.new(
    parse_servers("inputs/servers.txt"), # servers
    1000, # power_cap
    10000, # energy_cap
    0 # repeat
  )
  datacenter.init(
    "fifo",
    schedule_with_periodicity(parse_jobs("inputs/jobs2.txt")),
    parse_dependencies()
  )
  write_scheduling_to_file(datacenter.servers)
  validation(validation)
end

# simple first_fit verification
def test_first_fit_without_energy_constraint(validation)
  datacenter = Datacenter.new(
    parse_servers("inputs/servers.txt"),
    1000,
    10000,
    0
  )
  datacenter.init(
    "first_fit",
    schedule_with_periodicity(parse_jobs("inputs/jobs2.txt")),
    parse_dependencies()
  )
  write_scheduling_to_file(datacenter.servers)
  validation(validation)
end

# simple edf verification
def test_edf_without_energy_constraint(validation)
  datacenter = Datacenter.new(
    parse_servers("inputs/servers.txt"),
    1000,
    10000,
    0
  )
  datacenter.init(
    "edf",
    schedule_with_periodicity(parse_jobs("inputs/jobs2.txt")),
    parse_dependencies()
  )
  write_scheduling_to_file(datacenter.servers)
  validation(validation)
end

def test_edf_with_premption(validation)
  datacenter = Datacenter.new(
    parse_servers("inputs/servers.txt"),
    1000,
    10000,
    0
  )
  datacenter.init(
    "edf",
    schedule_with_periodicity(parse_jobs("inputs/jobs3.txt")),
    parse_dependencies()
  )
  write_scheduling_to_file(datacenter.servers)
  validation(validation)
end

test_fifo_without_energy_constraint(fifo_1_results)
test_first_fit_without_energy_constraint(first_fit_results)
test_edf_without_energy_constraint(edf_results)
test_edf_with_premption(edf_result_premption)
