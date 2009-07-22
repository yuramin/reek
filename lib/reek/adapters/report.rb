require 'set'
require 'reek/adapters/command_line'

module Reek
  class ReportSection
    include Enumerable

    def initialize(sniffer)  # :nodoc:
      @masked_warnings = SortedSet.new
      @warnings = SortedSet.new
      @desc = sniffer.desc
      sniffer.report_on(self)
    end

    def <<(smell)  # :nodoc:
      @warnings << smell
      true
    end

    def record_masked_smell(smell)
      @masked_warnings << smell
    end

    def num_masked_smells
      @masked_warnings.length
    end
    
    def empty?
      @warnings.empty?
    end

    def length
      @warnings.length
    end

    # Creates a formatted report of all the +Smells::SmellWarning+ objects recorded in
    # this report, with a heading.
    def full_report
      return quiet_report if Options[:quiet]
      result = header
      result += ":\n#{smell_list}" if should_report
      result += "\n"
      result
    end

    def quiet_report
      return '' unless should_report
      "#{header}:\n#{smell_list}\n"
    end

    def header
      @all_warnings = SortedSet.new(@warnings)      # SMELL: Temporary Field
      @all_warnings.merge(@masked_warnings)
      "#{@desc} -- #{visible_header}#{masked_header}"
    end

    # Creates a formatted report of all the +Smells::SmellWarning+ objects recorded in
    # this report.
    def smell_list
      smells = Options[:show_all] ? @all_warnings : @warnings
      smells.map {|smell| "  #{smell.report}"}.join("\n")
    end

  private

    def should_report
      @warnings.length > 0 or (Options[:show_all] and @masked_warnings.length > 0)
    end

    def visible_header
      num_smells = @warnings.length
      result = "#{num_smells} warning"
      result += 's' unless num_smells == 1
      result
    end

    def masked_header
      num_masked_warnings = @all_warnings.length - @warnings.length
      num_masked_warnings == 0 ? '' : " (+#{num_masked_warnings} masked)"
    end
  end

  class Report

    def initialize(sniffers)
      @partials = sniffers.map {|sn| ReportSection.new(sn)}
    end

    # SMELL: Shotgun Surgery
    # This method and the next will have to be repeated for every new
    # kind of report.
    def full_report
      @partials.map { |rpt| rpt.full_report }.join
    end

    def quiet_report
      @partials.map { |rpt| rpt.quiet_report }.join
    end
  end
end