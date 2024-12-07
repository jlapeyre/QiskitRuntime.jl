# eventually, we can store the three parts
# struct Instance
#     instance::String
# end

struct Account{PT}
    channel::String
    url::String
    token::String
    instance::String
    private_endpoint::Bool
    verify::Bool
    proxies::PT
end

function Account(channel, instance, url, token;
                 private_endpoint::Bool=false, verify::Bool=false,
                 proxies=nothing)
    return Account{typeof(proxies)}(channel, url, token, instance, private_endpoint,
                             verify, proxies)
end

function read_account_file()
    acct_file = joinpath(homedir(), ".qiskit", "qiskit-ibm.json")
    if ! isfile(acct_file)
        return nothing
    end
    acct_string = String(read(acct_file))
    acct_json = JSON.read(acct_string)

    # The only account is default-ibm-quantum.
    # This is dict-like, with a single keydefault-ibm-quantum.
    # We take just the value
    acct = first(acct_json)[2]
    return Account(acct.channel, acct.instance, acct.url, acct.token;
                   private_endpoint=acct.private_endpoint)
end

        # self.channel: str = None
        # self.url: str = None
        # self.token = token
        # self.instance = instance
        # self.proxies = proxies
        # self.verify = verify
        # self.private_endpoint: bool = False
