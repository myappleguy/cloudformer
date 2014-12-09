require 'cloudformer/version'
require 'cloudformer/task'
require 'rake/tasklib'

module Cloudformer
  class Tasks < Rake::TaskLib
    STANDARD_TASKS = [:apply, :delete, :force_delete, :status, :events, :outputs, :recreate, :stop, :start, :validate]
    attr_reader :tasks

    def initialize
      @tasks = []
      define_tasks
    end

    def self.add(stack_name)
      @@instance ||= self.new
      @task = Task.new(stack_name)
      if block_given?
        yield @task
        @@instance.tasks << @task
      end
    end

    def define_tasks
      STANDARD_TASKS.each do |task_sym|
        desc "#{task_sym.to_s.capitalize} to all Stacks."
        task task_sym, :stack_name do |t, args|
          tasks_to_run(task_sym, args[:stack_name]).each do |task|
            Rake::Task[task.name.to_sym].invoke
          end
        end
      end
    end

    private

    def tasks_by_type task_type
      #is this getting the tasks
      puts "TASKS: #{Rake.application.tasks}"
      Rake.application.tasks.select{ |t| t.name.start_with? task_type.to_s }
    end

    def task_by_name task_type, task_name
      tasks_by_type(task_type).select{ |t| t.name.end_with? task_name }
    end

    def tasks_to_run task_type, task_name
      if task_name
        tasks_by_name task_type, task_name
      else
        tasks_by_type task_type
      end
    end

  end
end
