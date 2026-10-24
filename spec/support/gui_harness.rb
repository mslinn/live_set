# gui_harness currently defines its debug helper as a top-level Log module. This
# project already uses Log as its Logger instance, so retain the project constant
# and keep the harness helper under GuiHarness::Log instead.
unless defined?(GuiHarness::LiveLauncher)
  project_logger = Object.const_get(:Log)
  Object.send(:remove_const, :Log)

  begin
    require 'gui_harness'
    harness_logger = Object.const_get(:Log)
    GuiHarness.const_set(:Log, harness_logger)
  ensure
    Object.send(:remove_const, :Log) if Object.const_defined?(:Log, false)
    Object.const_set(:Log, project_logger)
  end
end
