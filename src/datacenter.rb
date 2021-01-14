#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

class Datacenter
  attr_reader :servers, :power_cap, :energy_cap, :repeat, :power_used, :timestep, :deadline_missed
  def initialize(servers, power_cap, energy_cap, repeat)
    # an array of Ruby objects representing the servers
    @servers = servers
    # power_cap = 600 Watts
    @power_cap = power_cap.to_i
    # energy_cap = 10000 Joules
    @energy_cap = energy_cap.to_i
    # repeat = 2
    @repeat = repeat.to_i
    # the dependancies tree
    @dependancies = []
    # we assume all servers are off
    @power_used = Array.new
    # waiting queue for the tasks before being attributed to a server
    @job_queue = Array.new
    # timesteps
    @timestep = 0
    @deadline_missed = 0
    @quantum = 2
  end

  # check if job arrive and store it in the datacenter queue
  # return the jobs arrive at this timestep of time
  def job_arrival(jobs)
    # put new job in queue
    new_jobs = Array.new
    jobs.each do |job|
      if job.arrival == @timestep
        # update the deadline according to the current timestep
        job.deadline += @timestep
        @job_queue << job
        new_jobs << job
      end
    end
    return new_jobs
  end

  # keep track of all the power used
  # compute the current consumption
  # stores it in an array for record
  def current_power_used()
    consumption = 0
    @servers.each do |server|
      consumption += server.power
    end
    @power_used << consumption
  end

  # decrease by one the servers' relative duration members
  # return the number of servers/jobs running
  def synchronyse_servers_clocks()
    nb_running = 0
    @servers.each do |server|
      # decrease the scheduled finish time of all servers
      if !!server.job
        server.job.relative_duration -= (server.performance * server.frequencies.max)
        server.job.quantum += 1
        server.shutdown(@timestep) if server.job.relative_duration <= 0
        nb_running += 1
      end
    end
    return nb_running
  end

  # I choose to implement a "real time" scheduler
  # with discrete time. This method
  # decreases the relative time of servers
  # returns a queue of processes to execute
  def clock(jobs)
    # check the job arrival
    arrivals = job_arrival(jobs)
    # compute power consumption
    current_power_used()
    # get number of servers/jobs working
    nb_running = synchronyse_servers_clocks()
    # display unless the system is empty
    unless ARGV.include? "--silent" or (arrivals.empty? and @power_used.last == 0)
      puts "\n        *** Time #{@timestep} ***\n"
      arrivals.each do |job|
        puts "Job #{job.id} arrives, its deadline is #{job.deadline}"
      end
      puts "Job Running | Waiting | Power consumption\n" \
      "     #{nb_running}      |    #{@job_queue.length}    |      #{@power_used.last}\n"
      @job_queue.each do |job|
        unless job.deadline > @timestep
          @deadline_missed += 1
          puts "Warning! The job #{job.id} missed its deadline!"
        end
      end
    end
  end

  # find the less busy server to assign the elected job
  def elect_first_available_server(job)
    # job.quantum = @quantum
    @servers.each do |server|
      # unless the server run a job, execute the job on it and exit loop
      unless !!server.job
        server.call(@timestep, job)
        @job_queue.delete(job)
        break
      end
    end
  end

  # loop over the servers according to max(frequency) * performance
  # find the less busy server to assign the elected job
  # if more than one server finish at the same time
  # the most powerful is choosen
  def elect_most_powerful_server(job, power=nil)
    unless power
      power = @servers.map{ |server| server.performance * server.frequencies.max }
    end
    unless !!@servers[power.each_with_index.max[1]].job
      @servers[power.each_with_index.max[1]].call(@timestep, job)
      @job_queue.delete(job)
    else
      # exclude the server we tried from the candidates
      power[power.each_with_index.max[1]] = 0
      # unless there are only 0, we loop
      unless power.max == 0
        elect_most_powerful_server(job, power)
      end
    end
  end

  # check is there is jobs left to schedule
  # and if jobs are still running on the servers
  # return a bool
  def jobs_left?(jobs)
    server_empty = true
    @servers.each do |server|
      server_empty = false if !!server.job
    end
    return true unless server_empty && jobs.select {|job| job.end < 0}.empty?
    false
  end

  # check if power capacity is reached
  # display a message if true
  # return a boolean
  def power_cap_reached()
    reached = false
    if @power_used.last >= @power_cap
      reached = true
      unless ARGV.include? "--silent"
        puts "Power capacity is reached (#{@power_used.last}/#{@power_cap.to_s}), cannot schedule more tasks!"
      end
    end
    return reached
  end

  # the fifo implementation
  # return @servers
  def fifo()
    job = @job_queue.first
    elect_first_available_server(job)
  end

  # the first_fit implementation
  # choosing the task with the highest duration first
  # and the most powerful server
  # return @servers
  def first_fit()
    job = @job_queue.sort_by(&:duration).first
    elect_most_powerful_server(job)
  end

  # compute the density as: for_all_job(sum(job.duration / min(job.periodicity, job.period))
  # return a float
  def density_system(jobs)
    delta = 0
    jobs.each do |job|
      # ensure periodicity is not zero
      zero_safe = job.periodicity == 0 ? job.deadline + 1 : job.periodicity
      delta += job.duration.to_f / [zero_safe, job.deadline].min()
    end
    return delta
  end

  # compute the utilization as: for_all_job(sum(job.duration / job.period))
  # return a float
  def utilization_system(jobs)
    u = 0
    jobs.each do |job|
      # ensure periodicity is not zero
      zero_safe = job.periodicity == 0 ? next : job.periodicity.to_f
      u += job.duration / zero_safe
    end
    nb_cpu = @servers.map{|server| server.performance }.sum
    return u / nb_cpu
  end

  def check_duration_periodicity(jobs)
    u = utilization_system(jobs)
    d_greater = true
    jobs.each do |job|
      # ensure periodicity is not zero
      zero_safe = job.periodicity == 0 ? next : job.periodicity.to_f
      if job.duration >= zero_safe
        d_greater = false
        break
      end
    end
    return d_greater
  end

  def set_slowdown(jobs)
    if check_duration_periodicity(jobs)
      u = utilization_system(jobs)
      puts "All job deadlines (D) are greater or equal to all job periodicities.\n" \
      "It is known that the optimal slowdown is U (#{u.round(2)}) if D >= p.\n" \
      "Slowdown s is set to U (#{u.round(2)})"
      return u
    else
      puts "As all job deadlines (D) are not greater or equal to all job periodicities,\n" \
      "there is no necessary and sufficient condition for the tast set to be schedulable or not.\n" \
      "Checking if Delta <= 1 ..."
      delta = density_system(jobs)
      if delta <= 1
        puts "Delta <= 1. The task set is schedulable.\n" \
        "Slowdown s is set to Delta (#{delta})"
        return delta
      else
        puts "Delta >= 1. The task set is not schedulable, running at full speed!\n" \
        "Slowndown s is set to 1"
        return 1
      end
    end
  end

  def edf_feasability(jobs)
    u = utilization_system(jobs)
    # get the total performance of the servers
    cpu = 0
    @servers.each do |server|
      cpu += server.performance
    end
    puts "Necessary condition of the solution's feasability: U <= processors being #{u.round(3)} <= #{cpu}\n" \
    "(where #{cpu} corresponds to the sum of the server's performance (~ processors))\n"
    if u <= cpu
      puts "Solution is feasible"
    else
      puts "Solution is not feasable (Missed deadlines predicted)"
    end
  end

  def edf_deadline_check(jobs)
    jobs_deadline = jobs.sort_by(&:relative_deadline)
    max_deadline = j.last.relative_deadline
    timestep = 0
    jobs_deadline.each do |job|
      return false if timestep/@servers.length > job.relative_deadline
      timestep += job.duration
    end
    return true
  end

  # the edf implementation
  # choosing the task with the earliest deadline first
  # return @servers
  def edf()
    deadlines = []
    # we order the jobs in the waiting queue by their deadline
    job = @job_queue.sort_by(&:deadline).first
    @servers.each do |server|
      deadlines << server.job.deadline if !!server.job
    end
    # we get the server witht the job that have the highest deadline
    highest_deadline_server = @servers[deadlines.each_with_index.max[1]] unless deadlines.empty?
    # if there are no servers available and the task has an earliest deadline
    if deadlines.length == @servers.length
      # if the executed job have a lower deadline than the job candidate
      if job.relative_deadline < highest_deadline_server.job.relative_deadline
        # we end the executed job
        highest_deadline_server.job.end = @timestep
        # duplicate it (to have seperate start and end time)
        dub_job = highest_deadline_server.job.dup
        # we put the job back in the global queue
        @job_queue << dub_job
        highest_deadline_server.shutdown(@timestep)
        highest_deadline_server.call(@timestep, job)
        @job_queue.delete(job)
      end
    # else (if not all severs are busy) we give the job to the first server free found
    else
      elect_most_powerful_server(job)
    end
  end

  def round_robin()
    @servers.each do |server|
      if !!server.job and server.job.quantum == 1
        server.job.end = timestep
        dup_job = server.shutdown(@timestep)
        @job_queue << dup_job
      end
    end
    elect_most_powerful_server(@job_queue.first)
  end

  # the dependancy tree for WaveFront and CPM
  def dependancy_tree(dependancies)
    tree = []
    while !dependancies.empty?
      branch = [dependancies[0][0]]
      dependancies.each do |dependancy|
        if dependancy[0] == branch.last
          branch << dependancy[1]
          dependancies.delete(dependancy)
        end
      end
      tree << branch
    end
    return tree
  end

  # return an array of array representing the waves
  def get_waves()
    dependancies = @dependancies.dup
    waves = [[dependancies[0][0]]]
    while waves.flatten.uniq.sort != dependancies.flatten.uniq.sort
      wave = []
      new_root = waves.last.first
      dependancies.each do |d|
        if d.include?(new_root)
          wave << d[d.index(new_root) + 1]
        end
      end
      waves << wave
    end
    return waves
  end

  def wavefront()
    job = @job_queue.first
    waves = get_waves()
    # if the current job have a dependancy
    if waves.flatten.include?(job.id)
      waves.each do |wave|
        if wave.include?(job.id)
          nb_branch = wave.index(job.id)
          nb_branch = nb_branch % @servers.length
          server = @servers[nb_branch]
          # if a job is currently running on that server we prempte it
          if !!server.job
            server.job.end = timestep
            dup_job = server.shutdown(@timestep)
            @job_queue << dup_job
          end
          server.call(@timestep, job)
          @job_queue.delete(job)
          break
        end
      end
    else
      elect_most_powerful_server(job)
    end
  end

  def cpm()
    job = @job_queue.first
    nb_branch = -1
    # we check if the job has dependancy
    # if yes, on witch branch
    @dependancies.each do |d|
      if d.include?(job.id)
        nb_branch = @dependancies.index(d)
        break
      end
    end
    # if it has dependancy
    if nb_branch != -1
      # get the server to work on
      nb_branch = nb_branch % @servers.length
      server = @servers[nb_branch]
      # if a job is currently running on that server we prempte it
      if !!server.job
        server.job.end = timestep
        dup_job = server.shutdown(@timestep)
        @job_queue << dup_job
      end
      server.call(@timestep, job)
      @job_queue.delete(job)
    else
      elect_most_powerful_server(job)
    end
  end

  def algo_info(algo, jobs)
    case algo
    when "fifo"
      puts "Running FIFO \n"
    when "first_fit"
      puts "Running best fit. We execute jobs with the longest job duration on the most performant server \n"
    when "edf"
      puts "Running Earliest Deadline First with Constant Static Slowdown (CSS) " \
      "and a static slowdown of 1."
      # for edf we test the feasability
      edf_feasability(jobs)
      # s = set_slowdown(jobs)
    when "round_robin"
      puts "Running Round Robin \n"
    when "wavefront"
      puts "Running WaveFront \n" \
      "The dependancy tree is: #{@dependancies}"
    when "cpm"
      puts "Running Critical Path Merge (CPM) \n" \
      "The waves are: #{get_waves}"
    else
      display_usage()
    end
  end

  def run_algo(algo)
    case algo
    when "fifo"
      fifo()
    when "first_fit"
      first_fit()
    when "edf"
      edf()
    when "round_robin"
      round_robin()
    when "wavefront"
      wavefront()
    when "cpm"
      cpm()
    else
      display_usage()
    end
  end

  def init(algo, jobs, dependancies)
    @dependancies = dependancy_tree(dependancies) unless dependancies.nil?
    algo_info(algo, jobs)
    while jobs_left?(jobs)
      clock(jobs)
      unless power_cap_reached()
        @job_queue.length.times do
          run_algo(algo)
        end
      end
      @timestep += 1
    end
    return servers
  end
end