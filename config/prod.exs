use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# UcxUccWeb.Endpoint.load_from_system_env/1 dynamically.
# Any dynamic configuration should be moved to such function.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phoenix.digest task
# which you typically run after static files are built.
config :ucx_ucc, UcxUccWeb.Endpoint,
  url: [host: "localhost", port: 4021],
  https: [port: 4021,
    otp_app: :ucx_ucc,
    keyfile: "priv/key.pem",
    certfile: "priv/cert.pem"
  ],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:ucx_ucc, :vsn)

# uncomment the following lines if you would like to use a symlink
# for production releases. Change the second path in the tuple to
# point to an existing  directory on your server somewhere.
# config :ucx_ucc,
#   release_simlink_uploads: {"uploads", "/var/lib/ucx_ucc/uploads"}


# Do not print debug messages in production
#config :logger, level: :info

config :logger, [
  level: :info,
  backends: [:console],
  console: [level: :warn, format: "[$level] $metadata$message\n",
    metadata: [:module, :function]
  ],
]

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :ucx_ucc, UcxUccWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :ucx_ucc, UcxUccWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :ucx_ucc, UcxUccWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
if File.exists? "config/prod.secret.exs" do
  import_config "prod.secret.exs"
end
