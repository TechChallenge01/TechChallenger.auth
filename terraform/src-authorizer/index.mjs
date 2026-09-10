// Lambda authorizer (API Gateway HTTP API, formato "simple response").
//
// O token JWT do projeto e assinado com HS256 (chave simetrica compartilhada
// entre esta Lambda de auth e a TechChallenge API). O JWT authorizer nativo do
// API Gateway v2 so valida tokens assimetricos (RS256 via JWKS/OIDC), entao a
// validacao HS256 e feita aqui, usando apenas o modulo `crypto` nativo do Node
// (sem dependencias -> nao precisa de `npm install` / bundling).
import crypto from "node:crypto";

const SECRET = process.env.JWT_KEY || "";
const ISSUER = process.env.JWT_ISSUER || "";
const AUDIENCE = process.env.JWT_AUDIENCE || "";

const DENY = { isAuthorized: false };

function b64urlToBuf(segment) {
  return Buffer.from(segment.replace(/-/g, "+").replace(/_/g, "/"), "base64");
}

export const handler = async (event) => {
  try {
    const headers = event.headers || {};
    const raw = headers.authorization || headers.Authorization || "";
    const match = /^Bearer\s+(.+)$/i.exec(String(raw).trim());
    if (!match) return DENY;

    const parts = match[1].trim().split(".");
    if (parts.length !== 3) return DENY;
    const [h64, p64, s64] = parts;

    const header = JSON.parse(b64urlToBuf(h64).toString("utf8"));
    if (header.alg !== "HS256") return DENY;

    const expected = crypto.createHmac("sha256", SECRET).update(`${h64}.${p64}`).digest();
    const provided = b64urlToBuf(s64);
    if (expected.length !== provided.length || !crypto.timingSafeEqual(expected, provided)) {
      return DENY;
    }

    const payload = JSON.parse(b64urlToBuf(p64).toString("utf8"));
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp !== undefined && now >= Number(payload.exp)) return DENY;
    if (payload.nbf !== undefined && now < Number(payload.nbf)) return DENY;
    if (ISSUER && payload.iss !== ISSUER) return DENY;
    if (AUDIENCE) {
      const aud = payload.aud;
      const audOk = aud === AUDIENCE || (Array.isArray(aud) && aud.includes(AUDIENCE));
      if (!audOk) return DENY;
    }

    // O JwtTokenService da API emite role/name com as URIs de claim do .NET
    // (ClaimTypes.Role / ClaimTypes.Name); aceitamos as duas formas.
    const role =
      payload.role ??
      payload["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"] ??
      "";
    const name =
      payload.name ??
      payload.unique_name ??
      payload["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"] ??
      "";

    // Repassado para a API principal via $context.authorizer.* (ver apigateway.tf).
    return {
      isAuthorized: true,
      context: {
        sub: String(payload.sub ?? ""),
        cpf: String(payload.cpf ?? ""),
        role: String(role),
        name: String(name),
      },
    };
  } catch {
    return DENY;
  }
};
