RSpec::Matchers.define :have_current_version do |version|
  match do |actual|
    actual.current_version == version
  end
  failure_message_for_should do |actual|
    "expected #{actual} to have current version #{version}, but got #{actual.current_version}"
  end
end

RSpec::Matchers.define :have_next_version do |version|
  match do |actual|
    actual.next_version == version
  end
  failure_message_for_should do |actual|
    "expected #{actual} to have next version #{version}, but got #{actual.current_version}"
  end
end

RSpec::Matchers.define :have_history_like do |history_key|
  match do |actual|
    actual.rewind
    actual.read.strip == fixture(history_key)
  end
  failure_message_for_should do |actual|
    actual.rewind
    RSpec::Expectations::Differ.new.diff_as_string(actual.read.strip, fixture(history_key))
  end
end

RSpec::Matchers.define :have_changelog_like do |history_key|
  match do |actual|
    actual.changelog == fixture(history_key)
  end
  failure_message_for_should do |actual|
    RSpec::Expectations::Differ.new.diff_as_string(actual.changelog, fixture(history_key))
  end
end

RSpec::Matchers.define :have_release_log_like do |history_key|
  match do |actual|
    actual.release_log == fixture(history_key)
  end
  failure_message_for_should do |actual|
    if actual.release_log.nil?
      "release log was nil"
    else
      RSpec::Expectations::Differ.new.diff_as_string(actual.release_log, fixture(history_key))
    end
  end
end


