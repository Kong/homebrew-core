class Kong < Formula
  desc "Open source Microservices and API Gateway"
  homepage "https://docs.konghq.com"
  license "Apache License Version 2.0"

  KONG_VERSION = "3.2.1".freeze
  
  stable do
    url "https://github.com/Kong/kong/archive/refs/tags/#{KONG_VERSION}.tar.gz"
    sha256 "f1583cd7ae1c8e29daa6008b2ea493c432b918d0cf3faf918891eeb314ac1499"
  end

  head do
    url "https://github.com/Kong/kong.git", branch: "master"
  end

  env :std

  patch :DATA

  # this allows .proto files to be sourced from kong's homebrew prefix when
  # combined with include.install below (trace_service.proto, etc.)
  #
  # can be removed once our luarocks supplying thier own proto files:
  #   https://github.com/Kong/kong/pull/8918
  patch :p1, <<-PATCH.gsub(/^\s{2}/, "")
    diff --git a/kong/tools/grpc.lua b/kong/tools/grpc.lua
    index 7ed532a..cd23571 100644
    --- a/kong/tools/grpc.lua
    +++ b/kong/tools/grpc.lua
    @@ -72,6 +72,7 @@ function _M.new()
         "/usr/include",
         "kong/include",
         "spec/fixtures/grpc",
    +    "HOMEBREW_PREFIX/Cellar/kong/#{KONG_VERSION}/include",
       } do
         protoc_instance:addpath(v)
       end
  PATCH

  depends_on "openjdk" => :build
  depends_on "bazelisk" => :build
  depends_on "cmake" => :build
  depends_on "python" => :build
  depends_on "rust" => :build
  depends_on "automake" => :build
  depends_on "curl" => :build
  depends_on "git" => :build
  depends_on "libyaml" => :build
  depends_on "m4" => :build
  depends_on "protobuf" => :build
  depends_on "perl" => :build
  depends_on "coreutils" => :build
  depends_on "zlib" => :build

  def install
    kong_prefix = Formula["kong"].prefix

    system "HOME=/tmp/brew_home PATH=$(brew --prefix python)/libexec/bin:/usr/bin:$PATH bazel build //build:kong --action_env=HOME --action_env=INSTALL_DESTDIR=#{kong_prefix} --verbose_failures"

    prefix.install Dir["bazel-bin/build/kong-dev/*"]
    system "chmod", "-R", "u+w", "bazel-bin/external/openssl"
    prefix.install Dir["bazel-bin/external/openssl/openssl"]
    prefix.install "kong/include"
    bin.install "bin/kong"

    openssl_prefix = kong_prefix + "openssl/"
    openresty_prefix = kong_prefix + "openresty"

    bin.install_symlink "#{openresty_prefix}/nginx/sbin/nginx"
    bin.install_symlink "#{openresty_prefix}/bin/openresty"
    bin.install_symlink "#{openresty_prefix}/bin/resty"

    yaml_libdir = Formula["libyaml"].opt_lib
    yaml_incdir = Formula["libyaml"].opt_include

    system "${kong_prefix}/bin/luarocks",
           "--tree=#{prefix}",
           "make",
           "CRYPTO_DIR=#{openssl_prefix}",
           "OPENSSL_DIR=#{openssl_prefix}",
           "YAML_LIBDIR=#{yaml_libdir}",
           "YAML_INCDIR=#{yaml_incdir}"

  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! For Homebrew/homebrew-core
    # this will need to be a test that verifies the functionality of the
    # software. Run the test with `brew test kong`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end

__END__
diff --git a/build/luarocks/BUILD.luarocks.bazel b/build/luarocks/BUILD.luarocks.bazel
index 2b2e960..e0c5fa1 100644
--- a/build/luarocks/BUILD.luarocks.bazel
+++ b/build/luarocks/BUILD.luarocks.bazel
@@ -65,7 +65,7 @@ OPENSSL_DIR=$$WORKSPACE_PATH/$$(echo '$(locations @openssl)' | awk '{print $$1}'

 # we use system libyaml on macos
 if [[ "$$OSTYPE" == "darwin"* ]]; then
-    YAML_DIR=$$(brew --prefix)/opt/libyaml
+    YAML_DIR=HOMEBREW_PREFIX/opt/libyaml
 elif [[ -d $$WORKSPACE_PATH/$(BINDIR)/external/cross_deps_libyaml/libyaml ]]; then
     # TODO: is there a good way to use locations but doesn't break non-cross builds?
     YAML_DIR=$$WORKSPACE_PATH/$(BINDIR)/external/cross_deps_libyaml/libyaml
diff --git a/bin/kong b/bin/kong
--- a/bin/kong
+++ b/bin/kong
@@ -4,6 +4,7 @@ setmetatable(_G, nil)

 pcall(require, "luarocks.loader")
 
-package.path = (os.getenv("KONG_LUA_PATH_OVERRIDE") or "") .. "./?.lua;./?/init.lua;" .. package.path
+package.cpath = (os.getenv("KONG_LUA_CPATH_OVERRIDE") or "") .. "HOMEBREW_PREFIX/lib/lua/5.1/?.so;" .. package.cpath
+package.path = (os.getenv("KONG_LUA_PATH_OVERRIDE") or "") .. "./?.lua;./?/init.lua;" .. "HOMEBREW_PREFIX/share/lua/5.1/?.lua;HOMEBREW_PREFIX/share/lua/5.1/?/init.lua;" .. package.path
 
 require("kong.cmd.init")(arg)
diff --git a/kong/templates/kong_defaults.lua b/kong/templates/kong_defaults.lua
--- a/kong/templates/kong_defaults.lua
+++ b/kong/templates/kong_defaults.lua
@@ -1,5 +1,5 @@
 return [[
-prefix = /usr/local/kong/
+prefix = HOMEBREW_PREFIX/opt/kong/
 log_level = notice
 proxy_access_log = logs/access.log
 proxy_error_log = logs/error.log
@@ -166,8 +166,8 @@ lua_socket_pool_size = 30
 lua_ssl_trusted_certificate = NONE
 lua_ssl_verify_depth = 1
 lua_ssl_protocols = TLSv1.1 TLSv1.2 TLSv1.3
-lua_package_path = ./?.lua;./?/init.lua;
-lua_package_cpath = NONE
+lua_package_path = ./?.lua;./?/init.lua;HOMEBREW_PREFIX/share/lua/5.1/?.lua;HOMEBREW_PREFIX/share/lua/5.1/?/init.lua;;
+lua_package_cpath = HOMEBREW_PREFIX/lib/lua/5.1/?.so;;
 
 role = traditional
 kic = off
diff -r -u a/kong/cmd/prepare.lua b/kong/cmd/prepare.lua
--- a/kong/cmd/prepare.lua	2022-09-12 14:38:55.000000000 +0200
+++ b/kong/cmd/prepare.lua	2022-09-15 10:53:58.000000000 +0200
@@ -23,8 +23,8 @@

 Example usage:
  kong migrations up
- kong prepare -p /usr/local/kong -c kong.conf
- nginx -p /usr/local/kong -c /usr/local/kong/nginx.conf
+ kong prepare -p HOMEBREW_PREFIX -c kong.conf
+ nginx -p HOMEBREW_PREFIX -c HOMEBREW_PREFIX/nginx.conf

 Options:
  -c,--conf       (optional string) configuration file
diff -r -u a/kong/pdk/init.lua b/kong/pdk/init.lua
--- a/kong/pdk/init.lua	2022-09-12 14:38:55.000000000 +0200
+++ b/kong/pdk/init.lua	2022-09-15 10:54:21.000000000 +0200
@@ -49,7 +49,7 @@
 --
 -- @field kong.configuration
 -- @usage
--- print(kong.configuration.prefix) -- "/usr/local/kong"
+-- print(kong.configuration.prefix) -- "HOMEBREW_PREFIX"
 -- -- this table is read-only; the following throws an error:
 -- kong.configuration.prefix = "foo"

diff -r -u a/kong/runloop/plugin_servers/process.lua b/kong/runloop/plugin_servers/process.lua
--- a/kong/runloop/plugin_servers/process.lua	2022-09-12 14:38:55.000000000 +0200
+++ b/kong/runloop/plugin_servers/process.lua	2022-09-15 10:54:10.000000000 +0200
@@ -61,7 +61,7 @@
       local env_prefix = "pluginserver_" .. name:gsub("-", "_")
       _servers[i] = {
         name = name,
-        socket = config[env_prefix .. "_socket"] or "/usr/local/kong/" .. name .. ".socket",
+        socket = config[env_prefix .. "_socket"] or "HOMEBREW_PREFIX/" .. name .. ".socket",
         start_command = config[env_prefix .. "_start_cmd"] or ifexists("/usr/local/bin/"..name),
         query_command = config[env_prefix .. "_query_cmd"] or ifexists("/usr/local/bin/query_"..name),
       }
