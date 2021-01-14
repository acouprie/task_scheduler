#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

# usage example: ruby main.rb fifo inputs/test1.txt

require "./src/datacenter.rb"
require "./src/server.rb"
require "./src/job.rb"

# helper contains the functions called directly by this main.rb file
load "src/helper.rb"
# parse the input
# (likely from inputs/test1.txt given as second parameter of command line call)
load "src/parse_input.rb"

# and create a Datacenter object
datacenter = Datacenter.new(
    parse_servers(),
    @data["power_cap"],
    @data["energy_cap"],
    @data["repeat"]
)

# run from the first parameter given in the command line
# shall be fifo, first_fit, edf
datacenter.init(ARGV[0], schedule_with_periodicity(), parse_dependencies())
# write the output in file for plotter use
write_scheduling_to_file(datacenter.servers)
# write the power consumption to be plotter
write_power_to_file(datacenter.power_used)
# display a sum up of the execution on the command line output
# (and save it in outputs/sumup.txt)
display_result(datacenter)

# this should run the python script automaticaly 
# at the end of the computation according to the OS
# (Linux only has been tested - experimental)
display_graph()
