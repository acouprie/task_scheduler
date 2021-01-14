#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

class Server
  # We consider that Pmax is 200
  POWER_MAX = 200
  attr_reader :power, :queue, :id, :frequencies, :quantum, :performance
  attr_accessor :job
  def initialize(id, performance, frequencies)
    @id = id
    @performance = performance.to_f
    @frequencies = frequencies.map{|f| f.to_i}
    # the current job executing
    @job = nil
    # work at fmax by default
    @slowdown = 1
    # we assume the server is off
    @power = 0
    @queue = Array.new
  end

  # display info of events during this quantum of time
  def display_info(job)
    unless ARGV.include? "--silent"
      puts "Job #{job.id} of relative duration #{job.relative_duration} has been attributed to server #{(@id + 1)}"
    end
  end

  # simulate the power consumption
  def set_server(job)
    frequency = @frequencies[-1].to_f
    job_cost = job.relative_duration / @performance / frequency
    set_slowdown(frequency)
    set_power()
    return job_cost.round(1)
  end

  def call(timestep, job)
    @queue << job
    unless !!@job
      @job = job
      @job.start = timestep
    end
    job_cost = set_server(job)
    job.end = timestep + job_cost
    display_info(job)
  end

  def set_slowdown(frequency)
    @slowdown = frequency.to_i / @frequencies.max.to_i
  end

  def set_power()
    @power = POWER_MAX * @slowdown**2
  end

  # simulate the shutdown of the server
  # remove the job from the server
  # put power to 0
  # return a duplication of the job running
  def shutdown(timestep=nil)
    dub_job = nil
    # if a job is running (and timestep is given)
    if !!job and !timestep.nil?
      @job.quantum = 0
      dup_job = @job.dup
    end
    @job = nil
    @power = 0
    return dup_job
  end
end