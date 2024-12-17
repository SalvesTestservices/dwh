module Dump
  def dump(item)
    if Rails.env.development?
      custom_log = Logger.new('log/dev.log')

      case
      when (item.is_a? Array)
        custom_log.info(Rainbow(item).green)
      when (item.is_a? Integer)
        custom_log.info(Rainbow(item).blue)
      when (item.is_a? String)
        custom_log.info(item)
      else
        custom_log.info(Rainbow(item.to_json).red)
      end
    end
  end
end