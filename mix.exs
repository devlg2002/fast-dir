defmodule FastDir.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastdir,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :hackney, :ssl, :public_key]
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.18"}
    ]
  end

  defp escript do
    [main_module: FastDir.CLI]
  end
end
