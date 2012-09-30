def with_env(envs)
  old_vals = {}
  for key in envs.keys
    key_s = key.to_s
    old_vals[key_s] = ENV[key_s]
    ENV[key_s] = envs[key]
  end

  yield

ensure
  for key in old_vals.keys
    ENV[key] = old_vals[key]
  end
end
