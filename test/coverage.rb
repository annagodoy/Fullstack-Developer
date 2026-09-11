require "simplecov"

SimpleCov.start "rails" do
  cover "{app,lib}/**/*.rb"

  merge_subprocesses true

  coverage :line do
    minimum 90
  end
end
