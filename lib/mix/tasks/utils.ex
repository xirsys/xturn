defmodule Mix.Tasks.Utils do
  defmacro __using__([]) do
    quote do
      def app_name() do
        Mix.Project.config()[:app]
        |> Atom.to_string()
      end

      def app_vsn() do
        Mix.Project.config()[:version]
      end

      def app_port() do
        Mix.Project.config()[:app]
        |> Application.get_env(:port)
        |> Integer.to_string()
      end
    end
  end
end
