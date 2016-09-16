module Quest
  class RSpecRunner
    # Based loosely on https://github.com/guard/guard-rspec/blob/master/lib/guard/rspec/rspec_process.rb

    attr_reader :result

    def initialize(spec_file, spec_helper, tmp_status_file)
      @spec_file       = spec_file
      @spec_helper     = spec_helper
      @tmp_status_file = tmp_status_file
      @command         = "rspec #{spec_file} -r #{spec_helper} -f json -o #{tmp_status_file}"
      @exit_code = run_spec
      @result   = read_result
    end

    def run_spec
      begin
        pid = Kernel.spawn(@command)
        result = ::Process.wait2(pid)
        result.last.exitstatus
      rescue Errno::ENOENT => ex
        raise Failure, "Failed: #{@command} (#{ex})"
      end
    end

    def read_result
      begin
        JSON.parse(File.read(@tmp_status_file))
      rescue Errno::ENOENT => ex
        raise Failure, "Cannot open status file #{@tmp_status_file}, (#{ex})"
      end
    end

  end
end
