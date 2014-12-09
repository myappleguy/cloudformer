require 'cloudformer/version'
require 'cloudformer/stack'
require 'rake/tasklib'

module Cloudformer
 class Task < Rake::TaskLib
   def initialize(stack_name)
     @stack_name = stack_name
     @stack =Stack.new(stack_name)
     if block_given?
       yield self
       define_tasks
     end
   end

   attr_reader :stack_name
   attr_accessor :template, :parameters, :disable_rollback, :retry_delete, :capabilities, :notify

   private
   def define_tasks
     define_create_task
     define_validate_task
     define_delete_task
     define_delete_with_stop_task
     define_events_task
     define_status_task
     define_outputs_task
     define_recreate_task
     define_stop_task
     define_start_task
   end

   def define_create_task
     desc "Apply Stack with Cloudformation script and parameters."
     task "apply#{stack_name}".to_sym do
        if retry_delete
          @stack.delete
        end
        result = @stack.apply(template, parameters, disable_rollback, capabilities, notify)
        if result == :Failed then exit 1 end
        if result == :NoUpdates then exit 0 end
     end
   end

   def define_delete_task
     desc "Delete stack from CloudFormation"
     task "delete#{stack_name}".to_sym do
      begin
        exit 1 unless @stack.delete
      rescue
        puts "Stack deleted successfully."
      end
     end
   end

   def define_delete_with_stop_task
    desc "Delete stack after stopping all instances"
    task "force_delete#{stack_name}".to_sym do
      begin
        @stack.stop_instances
        exit 1 unless @stack.delete
      rescue => e
        puts "Stack delete message - #{e.message}"
      end
    end
   end

   def define_status_task
     desc "Get the deployed app status."
     task "status#{stack_name}".to_sym do
      @stack.status
     end
   end

   def define_events_task
     desc "Get the recent events from the stack."
     task "events#{stack_name}".to_sym do
       @stack.events
     end
   end

   def define_outputs_task
     desc "Get the outputs of stack."
     task "outputs#{stack_name}".to_sym do
       @stack.outputs
     end
   end
   def define_recreate_task
     desc "Recreate stack."
     task recreate => ["delete#{stack_name}".to_sym, "apply#{stack_name}".to_sym, "outputs#{stack_name}".to_sym]
   end

   def define_stop_task
    desc "Stop EC2 instances in stack."
    task "stop#{stack_name}".to_sym do
      @stack.stop_instances
    end
   end

   def define_start_task
    desc "Start EC2 instances in stack."
    task "start#{stack_name}".to_sym do
      @stack.start_instances
    end
   end

   def define_validate_task
    desc "Validate the Stack."
    task "validate#{stack_name}".to_sym do
      @stack.validate(template)
    end
   end
 end
end
