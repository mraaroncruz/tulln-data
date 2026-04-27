defmodule TullnData.Repo do
  use Ecto.Repo,
    otp_app: :tulln_data,
    adapter: Ecto.Adapters.Postgres
end
