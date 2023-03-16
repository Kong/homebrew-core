class Kong < Formula
  desc "Open source Microservices and API Gateway"
  homepage "https://docs.konghq.com"

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

  license "Apache License Version 2.0"

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
    system "HOME=/tmp/brew_home bazel build //build:kong --action_env=HOMEBREW_LIBRARY --action_env=HOME"
    prefix.install Dir["bazel-bin/build/kong-dev/*"]
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
