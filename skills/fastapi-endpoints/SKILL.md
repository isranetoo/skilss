---
name: fastapi-endpoints
description: Use quando for criar, revisar ou refatorar endpoints FastAPI — organização de routers, dependências, response_model, status codes, tratamento de erro, paginação e async vs sync. Não cobre autenticação completa, migrations nem deploy.
---

# FastAPI Endpoints

Convenções e armadilhas ao escrever rotas FastAPI. Foco no que costuma sair errado, não na
sintaxe básica.

## Quando usar

- Criar um endpoint novo (CRUD ou não)
- Revisar um router existente antes de merge
- Refatorar rotas que cresceram dentro do `main.py`

**Não use quando:** o assunto for modelagem Pydantic isolada, camada de banco/ORM, ou pipeline
de deploy.

## Estrutura de arquivos

Um router por recurso, agrupado por domínio. `main.py` só monta a aplicação.

```
app/
├── main.py                  # cria o FastAPI(), inclui routers, middlewares
├── api/
│   ├── deps.py              # dependências compartilhadas (get_db, get_current_user)
│   └── routers/
│       ├── users.py
│       └── orders.py
├── schemas/                 # modelos Pydantic (entrada/saída)
├── models/                  # entidades do ORM
└── services/                # regra de negócio — o router não faz lógica
```

Regra: **o router é fino**. Ele valida entrada, chama um service e devolve. Se uma função de
rota passa de ~20 linhas, a lógica pertence a `services/`.

```python
# app/api/routers/users.py
from fastapi import APIRouter, Depends, status

router = APIRouter(prefix="/users", tags=["users"])

@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(payload: UserCreate, db: Session = Depends(get_db)) -> UserOut:
    return await user_service.create(db, payload)
```

```python
# app/main.py
app.include_router(users.router, prefix="/api/v1")
```

O `prefix` do recurso fica no `APIRouter`; o prefixo de versão fica no `include_router`. Não
duplique os dois no mesmo lugar.

## Contrato do endpoint

**Sempre declare `response_model`.** Sem ele o FastAPI serializa o objeto cru — é assim que
`hashed_password` vaza. O `response_model` é filtro de saída, não só documentação.

**Sempre declare `status_code` quando não for 200.** `201` para criação, `204` para delete sem
corpo (e a função retorna `None`), `202` para trabalho assíncrono.

**Schemas separados por direção.** `UserCreate` (entrada), `UserUpdate` (entrada parcial),
`UserOut` (saída). Nunca reaproveite o modelo do ORM como schema de entrada — vira mass
assignment.

Para `PATCH`, use campos opcionais e `exclude_unset` ao aplicar:

```python
data = payload.model_dump(exclude_unset=True)   # Pydantic v2
```

Sem `exclude_unset`, um PATCH sobrescreve tudo que não foi enviado com `None`.

## Dependências

Coloque em `deps.py` e injete com `Depends`. Dependência com `yield` para recursos que precisam
de fechamento:

```python
def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

Para exigir auth em todas as rotas de um router, use `dependencies=` no próprio router em vez de
repetir em cada função:

```python
router = APIRouter(prefix="/admin", dependencies=[Depends(require_admin)])
```

Dependências são **cacheadas por request** por padrão — a mesma `Depends(get_db)` em três lugares
do mesmo request devolve a mesma sessão. Use `Depends(x, use_cache=False)` só quando quiser
execução repetida.

## Erros

Levante `HTTPException` na fronteira (router) e exceções de domínio no service. Traduza as de
domínio com um handler global, não com `try/except` em cada rota:

```python
@app.exception_handler(NotFoundError)
async def not_found_handler(request: Request, exc: NotFoundError):
    return JSONResponse(status_code=404, content={"detail": str(exc)})
```

Nunca devolva o texto de uma exceção do banco na resposta — vaza schema e credenciais. Logue o
original, responda genérico.

## async vs sync

| Situação | Assinatura |
|---|---|
| I/O com biblioteca async (`httpx`, `asyncpg`, SQLAlchemy async) | `async def` |
| Driver **síncrono** (`psycopg2`, `requests`, SQLAlchemy sync) | `def` |
| CPU-bound | `def` (ou mande para worker) |

Armadilha principal: chamada bloqueante dentro de `async def` trava o event loop e derruba a
concorrência da aplicação inteira. Se a função tem `async def` mas usa driver síncrono, ou troque
o driver, ou tire o `async`. FastAPI roda `def` em threadpool automaticamente.

## Paginação e listagem

Nunca devolva coleção sem limite. Use `Query` com limite máximo:

```python
@router.get("", response_model=Page[UserOut])
async def list_users(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
) -> Page[UserOut]:
    ...
```

Devolva o total junto com os itens (`{"items": [...], "total": n}`), senão o cliente não consegue
paginar.

## Armadilhas frequentes

- **Ordem de rotas importa.** `/users/me` precisa ser declarada *antes* de `/users/{user_id}`,
  senão `me` é capturado como id.
- **`response_model` com `Depends` de ORM lazy.** Se a sessão fechou antes da serialização, o
  acesso a relacionamento estoura. Carregue explicitamente (`selectinload`) ou converta dentro do
  service.
- **Mutável como default.** `def f(tags: list[str] = [])` compartilha a lista entre requests. Use
  `Query(default_factory=list)` ou `None`.
- **`status_code=204` retornando corpo.** Retorne `None`; qualquer corpo com 204 quebra clientes.
- **Validação de path com tipo.** `user_id: int` já devolve 422 automático — não valide à mão.
- **Endpoint sem `tags`.** A doc gerada vira uma lista única ilegível; sempre passe `tags` no
  `APIRouter`.

## Checklist de revisão

- [ ] `response_model` declarado e não expõe campo sensível
- [ ] `status_code` correto para a semântica (201/204/202)
- [ ] Schema de entrada separado do modelo de ORM
- [ ] `async def` só com I/O realmente assíncrono
- [ ] Listagem com `limit` máximo
- [ ] Erros de domínio traduzidos por handler, sem vazar detalhe interno
- [ ] Rota estática declarada antes da rota com path param equivalente
- [ ] Router registrado no `main.py` com o prefixo de versão
