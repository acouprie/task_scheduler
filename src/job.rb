#!/usr/bin/env ruby
# @author: Antoine Couprie
# @date: 2020
# M2 Computer Science for Aerospace - University Paul Sabatier

class Job
  attr_reader :id, :duration, :periodicity
  attr_accessor :arrival, :end, :start, :deadline, :relative_deadline, :relative_duration, :quantum

  def initialize(id,arrival,duration,deadline,periodicity)
    @id=id
    @arrival=arrival
    @duration=duration
    @relative_duration=duration
    @relative_deadline=arrival+deadline
    @deadline=deadline
    @periodicity=periodicity
    @quantum=0
    # -1 to show that the task never runned
    @start=-1
    # -1 to show that the job is not executed
    @end=-1
  end
end