module Quest
  class RSpecRunner
    # Based loosely on https://github.com/guard/guard-rspec/blob/master/lib/guard/rspec/rspec_process.rb

    attr_reader :result

    def initialize(spec_file, spec_helper)
      @spec_file       = spec_file
      @spec_helper     = spec_helper
      Tempfile.open('quest-rspec-runner') do |tmp_file|
        @exit_code = run_spec(@spec_file, @spec_helper, tmp_file.path)
        @result   = read_result(tmp_file.path)
      end
    end

    def run_spec(spec_file, spec_helper, tmp_file)
      home = ENV["HOME"] || '/tmp'
      command  = "HOME=#{home} rspec #{spec_file} -r #{spec_helper} -f json -o #{tmp_file}"
      begin
        pid = Kernel.spawn(command)
        result = ::Process.wait2(pid)
        result.last.exitstatus
      rescue Errno::ENOENT => ex
        raise Failure, "Failed: #{command} (#{ex})"
      end
    end

    def read_result(tmp_file)
      begin
        JSON.parse(File.read(tmp_file))
      rescue Errno::ENOENT => ex
        raise Failure, "Cannot open status file #{tmp_file}, (#{ex})"
      end
    end

  end
end
