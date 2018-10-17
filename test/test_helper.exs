File.mkdir_p!(Application.app_dir(:clover, "ex_unit"))
ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
