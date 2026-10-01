# SneakerClean Frontend 👟

Interface administrativa do SneakerClean para uma operação de limpeza e restauração de tênis. O frontend é uma SPA Vue 3 que consome a API REST do SneakerClean para autenticação, clientes, ordens de serviço, usuários e métricas.

> Os registros e as regras de negócio são mantidos no backend. O navegador guarda o token de autenticação, mas não é a fonte de verdade dos dados.

## ✨ Funcionalidades

- Login JWT, com opção para exibir ou ocultar a senha.
- Dashboard de faturamento do mês, OS abertas e OS concluídas.
- Cadastro, pesquisa, paginação, edição e desativação de clientes.
- Máscaras de telefone/WhatsApp e CEP durante a digitação.
- Criação de OS para cliente cadastrado, com vários tênis e vários serviços por tênis.
- Subtotal calculado em tempo real e envio dos serviços como itens da OS.
- Listagem e filtros de OS por status, mês e ano; edição de OS em andamento e atualização de status.
- Impressão individual de OS pelo navegador, com opção de salvar como PDF.
- Cadastro, edição, listagem e desativação de usuários na área Admin.

## 🖥️ Telas e navegação

O projeto não usa Vue Router. As telas são alternadas por abas controladas por `activeView` no componente `src/App.vue`.

- **Login:** envia credenciais para `POST /api/auth/login`, guarda o token e inicia o dashboard após autenticação.
- **Dashboard:** busca as métricas em `GET /api/dashboard/metrics`.
- **Ordens de Serviço:** carrega clientes ativos para seleção; permite cadastrar vários tênis e serviços, ver totais, filtrar/listar OS, editar OS em andamento, trocar status e imprimir uma ordem individual.
- **Clientes:** formulário de cadastro/edição, tabela paginada, busca por nome ou telefone e desativação.
- **Usuários:** visível apenas para Admin; permite criar, editar nome/e-mail/perfil, listar e desativar usuários. A senha é informada na criação; a tela não altera a senha existente.

O perfil Admin controla a navegação visível no frontend, mas a API também valida a autorização. Ocultar uma aba não substitui a autorização do servidor.

## 🧩 Organização do código

```text
src/
├── App.vue                    # Login, dashboard, abas e métricas
├── main.js                    # Inicialização da aplicação Vue
├── assets/main.css            # Tema e estilos globais
├── components/
│   ├── OrdersView.vue         # Criação e gestão de OS
│   ├── CustomersView.vue      # CRUD, busca e paginação de clientes
│   └── UsersView.vue          # Gestão de usuários para Admin
└── services/
	└── api.js                 # Axios, base URL e interceptor JWT
```

Os componentes usam Vue Composition API e `<script setup>`. O estado de cada módulo fica no próprio componente; o token e o perfil são persistidos no `localStorage`.

## 🔌 Comunicação com a API

`src/services/api.js` cria uma instância Axios compartilhada. A URL base é definida por `VITE_API_BASE_URL`; sem essa variável, o valor padrão é `http://localhost:5000/api`. Um interceptor anexa `Authorization: Bearer <token>` quando existe `prime_token` no `localStorage`.

Os caminhos abaixo são relativos à URL base:

| Tela/operação           | Método e caminho                                       | Autorização |
| ----------------------- | ------------------------------------------------------ | ----------- |
| Login                   | `POST /auth/login`                                     | Público     |
| Métricas                | `GET /dashboard/metrics`                               | JWT         |
| Listar clientes         | `GET /customers?page=&pageSize=&search=`               | JWT         |
| Clientes ativos para OS | `GET /customers/all`                                   | JWT         |
| Obter cliente           | `GET /customers/{id}`                                  | JWT         |
| Criar cliente           | `POST /customers`                                      | JWT         |
| Editar cliente          | `PUT /customers/{id}`                                  | JWT         |
| Desativar cliente       | `DELETE /customers/{id}`                               | Admin       |
| Listar OS               | `GET /orders?status=&month=&year=&customerId=&search=` | JWT         |
| Obter OS                | `GET /orders/{id}`                                     | JWT         |
| Criar OS                | `POST /orders`                                         | JWT         |
| Editar OS/status/itens  | `PUT /orders/{id}`                                     | JWT         |
| Atualizar apenas status | `PATCH /orders/{id}/status`                            | JWT         |
| Cancelar OS             | `DELETE /orders/{id}`                                  | JWT         |
| Listar usuários         | `GET /users`                                           | Admin       |
| Criar usuário           | `POST /users`                                          | Admin       |
| Editar usuário          | `PUT /users/{id}`                                      | Admin       |
| Desativar usuário       | `DELETE /users/{id}`                                   | Admin       |

### Contrato de OS multi-serviço

Na interface, os serviços ficam agrupados no tênis ao qual pertencem. Para respeitar o contrato atual da API, o frontend achata essa estrutura ao enviar a OS: cada serviço vira um elemento em `items[]`, repetindo marca, modelo, cor e tamanho do tênis. O backend soma os preços dos itens e calcula o total.

Os status enviados à API são `Open`, `InProgress`, `Completed`, `Cancelled` e `Delivered`; a interface apresenta seus rótulos em português. A impressão chama `window.print()` e usa CSS de impressão para mostrar somente a OS selecionada. O arquivo PDF é produzido pela função “Salvar como PDF” do navegador, não pelo servidor.

## 🔐 Sessão e segurança

O frontend salva `prime_token`, `prime_role` e `prime_user_id` no `localStorage`. O token é anexado às chamadas Axios; ao sair, os valores são removidos. A aba de usuários é restrita visualmente ao papel Admin, enquanto as permissões reais são verificadas pelo backend.

O `localStorage` é usado para o cenário atual de desenvolvimento. Em produção, use HTTPS, configure CORS restritivo no backend e avalie uma estratégia de sessão com cookie `HttpOnly` conforme o modelo de segurança da aplicação. Não coloque senhas, chaves JWT ou outros segredos em variáveis `VITE_*`: elas são incorporadas ao bundle público.

## 🛠️ Tecnologias

- **Vue 3.4** e Composition API — componentes e estado local.
- **Vite 5** — desenvolvimento e build.
- **Axios 1.6** — integração HTTP.
- **Lucide Vue Next 0.344** — ícones.
- **Node.js 22** — etapa de compilação Docker.
- **Nginx Alpine** — servidor dos arquivos estáticos.

As dependências e scripts (`dev`, `build` e `preview`) estão definidos em `package.json`.

## 🚀 Executar localmente

### Pré-requisitos

- Node.js 22 e npm.
- API SneakerClean acessível. Para banco, Redis e RabbitMQ, pode-se iniciar o Compose do backend.

Na pasta `sneakerclean-frontend`, instale as dependências:

```bash
npm ci
```

**PowerShell:**

```powershell
$env:VITE_API_BASE_URL = "http://localhost:5000/api"
npm run dev -- --host 0.0.0.0
```

**Linux/macOS/Git Bash:**

```bash
VITE_API_BASE_URL=http://localhost:5000/api npm run dev -- --host 0.0.0.0
```

Abra `http://localhost:5173`. A API também precisa permitir a origem local do Vite na configuração CORS.

### Build e preview

```bash
npm run build
npm run preview
```

O resultado estático é gravado em `dist/`.

## 🐳 Executar com Docker

O Dockerfile deste repositório usa build multi-stage: Node.js 22 compila a aplicação e Nginx Alpine serve os arquivos da pasta `dist` na porta 80.

### Stack completa

Para subir API, frontend, SQL Server, Redis e RabbitMQ, os diretórios `sneakerclean-backend` e `sneakerclean-frontend` devem ficar lado a lado. O Compose está no backend:

```bash
cd sneakerclean-backend
docker compose up -d --build
docker compose ps
```

O frontend fica em `http://localhost:3000`, e a API em `http://localhost:5000`. Consulte o README do backend para portas, credenciais de desenvolvimento, logs e detalhes do banco.

```bash
docker compose logs -f frontend
docker compose stop
docker compose start
```

O Compose atual não declara volume para o SQL Server. `docker compose stop` preserva o container; `docker compose down` remove os containers e pode remover dados que não tenham sido copiados para um volume.

### Imagem isolada do frontend

Com a API já disponível em `http://localhost:5000/api`, a partir da pasta `sneakerclean-frontend`:

```bash
docker build -t sneakerclean-frontend .
docker run --rm -p 3000:80 sneakerclean-frontend
```

O bundle usa por padrão `http://localhost:5000/api`. Defina a URL correta antes de executar o build se a API estiver hospedada em outro endereço.

## 🧪 Verificações

```bash
npm run build
```

O projeto frontend não possui uma suíte de testes automatizados configurada atualmente. A API e seus testes unitários ficam no repositório `sneakerclean-backend`.

## ⚠️ Validações e limites

- Os formulários aplicam restrições HTML e máscaras de CEP/telefone; as regras de negócio são novamente validadas pela API com FluentValidation e pelas entidades do domínio.
- O frontend não calcula nem envia um total autoritativo da OS: envia os serviços e exibe a soma para conveniência; o backend calcula o total persistido.
- Não há rotas de navegação Vue Router; os módulos são abas de uma única página.
- O consumidor RabbitMQ, o banco de dados e a autorização são responsabilidades do backend, não deste bundle estático.

---

Frontend do sistema SneakerClean. 👟✨

Learn more about IDE Support for Vue in the [Vue Docs Scaling up Guide](https://vuejs.org/guide/scaling-up/tooling.html#ide-support).
