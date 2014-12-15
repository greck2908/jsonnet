/*
Copyright 2014 Google Inc. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

{
    local terraform = self,

    // Basic template for a GCP instance, adds default service account scopes, and factors out a few
    // things into top-level fields.
    GcpInstance:: {
        local instance = self,
        name: error "Instance must have field: name",
        image:: error "Instance must have field: image",
        address:: null,

        scopes:: ["devstorage.read_only"],

        service_accounts: [
            {
                email: "default",
                scopes: ["https://www.googleapis.com/auth/" + s for s in instance.scopes],
            }
        ],

        machine_type: "f1-micro",
        zone: "us-central1-f",
        tags: ["terraform"],

        disk: {
            image: instance.image,
        },

        startup_script:: [],

        addFile(v, dest)::
            "echo %s > %s" % [std.escapeStringBash("" + v), dest],

        metadata: {
            "startup-script": std.lines(instance.startup_script),
        },

        network: {
            source: "default",
            [if instance.address != null then "address"]: instance.address,
        },

    },

    // Allow http for servers tagged with "http-server" on the given network.
    GcpFirewallHttp:: {
        local fw = self,
        network:: error "GcpFirewallHttp must have field: network",
        http: {
            name: "http",
            source_ranges: ["0.0.0.0/0"],
            network: fw.network,
            allow: [{ protocol: "tcp", ports: ["80"] }],
            target_tags: ["http-server"],
        },
    },

    // Allow ssh for all servers on the given network.
    GcpFirewallSsh:: {
        local fw = self,
        network:: error "GcpFirewallHttp must have field: network",
        ssh: {
            name: "ssh",
            source_ranges: ["0.0.0.0/0"],
            network: fw.network,
            allow: [{ protocol: "tcp", ports: ["22"] }],
        },
    },
}