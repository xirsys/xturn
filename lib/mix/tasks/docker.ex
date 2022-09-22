defmodule Mix.Tasks.Docker do
  use Mix.Task
  use Mix.Tasks.Utils

  @shortdoc "Docker utilities for building releases"
  def run([env]) do
    # Build a fresh Elixir image, in case Dockerfile has changed
    build_image(env)

    # Get the current working directory
    {dir, _resp} = System.cmd("pwd", [])

    # Mount the working directory at /opt/build within the new elixir image
    # Execute the /opt/build/bin/release script
    docker(
      "run -v #{String.trim(dir)}:/opt/build --rm -i #{app_name()}:latest /opt/build/bin/release #{env}"
    )
  end

  defp build_image(env) do
    docker("build --build-arg ENV=#{env} -t #{app_name()}:latest .")
  end

  defp docker(cmd) do
    System.cmd("docker", String.split(cmd, " "), into: IO.stream(:stdio, :line))
  end
end
