# Why an import couldn't produce a Draft. `reason` is stored on the Draft and shown from drafts.failures.<reason>.
class ImportFailure < StandardError
  attr_reader :reason

  def initialize(reason, message = reason.to_s)
    @reason = reason
    super(message)
  end
end
