use t::APISIX 'no_plan';

repeat_each(1);
no_long_string();
no_root_location();

add_block_preprocessor(sub {
    my ($block) = @_;

    # setup default conf.yaml
    my $extra_yaml_config = $block->extra_yaml_config // <<_EOC_;
plugins:
    - gm
_EOC_

    $block->set_value("extra_yaml_config", $extra_yaml_config);

    if (!$block->request) {
        $block->set_value("request", "GET /t");
    }

    if ((!defined $block->error_log) && (!defined $block->no_error_log)) {
        $block->set_value("no_error_log", "[error]");
    }
});

run_tests;

__DATA__

=== TEST 1: set ssl
--- config
location /t {
    content_by_lua_block {
        local core = require("apisix.core")
        local t = require("lib.test_admin")

        local f = assert(io.open("t/certs/server_enc.crt"))
        local cert_enc = f:read("*a")
        f:close()

        local f = assert(io.open("t/certs/server_sign.crt"))
        local cert_sign = f:read("*a")
        f:close()

        local f = assert(io.open("t/certs/server_enc.key"))
        local pkey_enc = f:read("*a")
        f:close()

        local f = assert(io.open("t/certs/server_sign.key"))
        local pkey_sign = f:read("*a")
        f:close()

        local data = {cert = cert_enc,
            key = pkey_enc,
            certs = {cert_sign},
            keys = {pkey_sign},
            sni = "localhost",
            gm = true,
        }

        local code, body = t.test('/apisix/admin/ssls/1',
            ngx.HTTP_PUT,
            core.json.encode(data)
        )

        if code >= 300 then
            ngx.status = code
            ngx.say(body)
            return
        end

        local code, body = t.test('/apisix/admin/routes/1',
            ngx.HTTP_PUT,
            [[{
                "upstream": {
                    "nodes": {
                        "127.0.0.1:1980": 1
                    },
                    "type": "roundrobin"
                },
                "uri": "/echo"
            }]]
        )

        ngx.say(body)
    }
}
--- response_body
passed



=== TEST 2: hit
--- exec
openssl s_client -connect localhost:1994 -servername localhost -cipher ECDHE-SM2-WITH-SM4-SM3 -enable_ntls -ntls -verifyCAfile t/certs/gm_ca.crt -sign_cert t/certs/client_sign.crt -sign_key t/certs/client_sign.key -enc_cert t/certs/client_enc.crt -enc_key t/certs/client_enc.key
--- response_body eval
qr/^CONNECTED/
--- no_error_log
SSL_do_handshake() failed
[error]



=== TEST 3: reject bad SSL
--- config
location /t {
    content_by_lua_block {
        local core = require("apisix.core")
        local t = require("lib.test_admin")

        local f = assert(io.open("t/certs/server_enc.crt"))
        local cert_enc = f:read("*a")
        f:close()

        local f = assert(io.open("t/certs/server_enc.key"))
        local pkey_enc = f:read("*a")
        f:close()

        local data = {
            cert = cert_enc,
            key = pkey_enc,
            sni = "localhost",
            gm = true,
        }

        local code, body = t.test('/apisix/admin/ssls/1',
            ngx.HTTP_PUT,
            core.json.encode(data)
        )

        if code >= 300 then
            ngx.status = code
            ngx.print(body)
            return
        end
    }
}
--- error_code: 400
--- response_body
{"error_msg":"sign cert\/key are required"}



=== TEST 4: hit with gm disabled
--- extra_yaml_config
--- exec
openssl s_client -connect localhost:1994 -servername localhost -cipher ECDHE-SM2-WITH-SM4-SM3 -enable_ntls -ntls -verifyCAfile t/certs/gm_ca.crt -sign_cert t/certs/client_sign.crt -sign_key t/certs/client_sign.key -enc_cert t/certs/client_enc.crt -enc_key t/certs/client_enc.key
--- response_body
--- error_log
SSL_do_handshake() failed
