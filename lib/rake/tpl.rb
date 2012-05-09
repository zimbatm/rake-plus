require 'ostruct'
require 'erb'

def tpl(name, target, variables={})
  ctx = OpenStruct.new(variables)
  tpl_str = File.read(SRC_DIR / "tpl/#{name}.erb")
  tpl = ERB.new(tpl_str)
  out = tpl.result ctx.send(:binding)
  FileUtils.mkdir_p File.dirname(target)
  File.open(target, 'w') do |f| f.write out end
end
