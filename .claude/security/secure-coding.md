# Secure Coding Standard

Every agent on the dev team follows this standard. It is based on the OWASP Top 10 and
OWASP ASVS. The `security-reviewer` checks every change against it. A **Critical** or
**High** finding blocks the change.

## 1. Secrets and credentials
- Never hard-code secrets, API keys, tokens, passwords, private keys or connection strings.
  Read them from environment variables or a secrets manager.
- Never read, print, log, copy or commit `.env` files, key files or credential stores.
- Use `.env.example` with placeholder values to document required variables.
- Make sure `.gitignore` covers `.env*`, `*.pem`, `*.key`, credential files and local DBs.

## 2. Input validation and injection
- Treat **all** external input as untrusted: request bodies, query strings, headers, cookies,
  files, env vars, CLI args, database rows written by users, and responses from other services.
- Validate on the server side with allow-lists (type, length, format, range).
- **SQL:** only parameterised queries or a safe ORM API. Never build SQL with string concatenation.
- **OS commands:** avoid shelling out. If unavoidable, pass an argument array (no shell) and never
  interpolate user input into a command string.
- **Paths:** normalise paths and reject `..` and absolute paths. Keep file access inside an
  allowed base directory.
- **Other interpreters:** never pass user input to `eval`, `exec`, `Function()`, template compilers,
  deserialisers (`pickle`, `yaml.load`, Java/.NET binary serialisation), LDAP, XPath or NoSQL operators.
- **XML:** disable external entities (XXE).

## 3. Output encoding (XSS and friends)
- Use the framework's auto-escaping. Avoid `innerHTML`, `dangerouslySetInnerHTML`, `v-html`,
  `|safe` and `mark_safe` unless the content is sanitised with a vetted library.
- Encode for the context: HTML, attribute, JS, URL or CSS.
- Set a Content-Security-Policy where the project serves HTML.

## 4. Authentication and sessions
- Never write your own crypto or password hashing. Use argon2id, scrypt or bcrypt through a
  maintained library.
- Use the framework's session handling. Cookies: `HttpOnly`, `Secure`, `SameSite=Lax` or `Strict`.
- Rate-limit login, password reset and other enumeration-prone endpoints. Give generic error
  messages ("invalid credentials").
- Tokens: short-lived, signed, validate `alg`, `exp`, `aud` and `iss`. Never accept `alg: none`.

## 5. Authorisation
- Deny by default. Check permissions **on the server** for every request, including object-level
  checks (can *this* user access *this* record?), to prevent IDOR.
- Never trust client-supplied roles, prices, user IDs or `isAdmin` flags.
- Protect state-changing requests against CSRF (framework tokens or SameSite cookies).

## 6. Cryptography and transport
- TLS for all network traffic. Never disable certificate verification (`verify=False`,
  `rejectUnauthorized: false`, `InsecureSkipVerify`).
- Use a cryptographically secure RNG for tokens and IDs (`secrets`, `crypto.randomBytes`,
  `crypto/rand`), never `Math.random` or `random`.
- Use modern algorithms only (AES-GCM, ChaCha20-Poly1305, SHA-256+). No MD5, SHA-1, DES or ECB.

## 7. Errors and logging
- Never return stack traces, SQL errors or internal paths to users.
- Log security events (login failures, permission denials), but **never** log secrets, tokens,
  passwords or full personal data.
- Fail closed: on an error in an auth or validation path, deny.

## 8. Dependencies and supply chain
- Prefer the standard library and existing dependencies. Add a new dependency only when needed,
  and justify it in your report.
- Only well-maintained, widely used packages. Double-check the exact name, because
  typosquatting is real.
- Pin versions with a lockfile. Never `curl | sh` or install from untrusted URLs.
- Run the ecosystem's audit tool (see section 11) and do not introduce known-vulnerable versions.

## 9. Resource safety
- Put limits on request sizes, uploads, pagination, loops over user data and regex input (ReDoS).
- Set timeouts on all outbound network calls.
- Uploads: check type and size, store outside the web root, use generated file names.
- SSRF: when fetching user-supplied URLs, allow-list hosts and block internal/metadata IP ranges.

## 10. Safe defaults in code and config
- Debug mode off in production config. No default or admin passwords.
- Least privilege for DB users, API keys, containers (non-root) and file permissions.
- Security headers where applicable: HSTS, X-Content-Type-Options, frame-ancestors.

## 11. Scanning tools (use if installed; do not install without asking the user)
| Purpose | Tools |
|---|---|
| Secrets | `gitleaks detect --no-git -v`, `trufflehog filesystem .` |
| Static analysis | `semgrep --config auto`, `bandit -r .` (Python), `gosec ./...` (Go), ESLint security plugins |
| Dependencies | `npm audit`, `pnpm audit`, `pip-audit`, `osv-scanner -r .`, `cargo audit`, `dotnet list package --vulnerable`, `govulncheck ./...` |

## Severity scale
| Severity | Meaning | Action |
|---|---|---|
| Critical | Exploitable remotely with serious impact (RCE, auth bypass, SQLi, leaked secret) | Block, fix now |
| High | Likely exploitable, or significant data exposure | Block, fix now |
| Medium | Exploitable under conditions, or defence-in-depth gap | Fix in this change if small, else log follow-up |
| Low / Info | Hardening suggestion | Report only |
