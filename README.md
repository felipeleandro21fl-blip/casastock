# CasaStock Compartilhado

Versão do CasaStock com:
- Login por e-mail e senha
- Banco PostgreSQL no Supabase
- Casas compartilhadas
- Código de convite
- Estoque compartilhado
- Lista de compras
- Segurança por Row Level Security (RLS)
- Sincronização em tempo real entre dispositivos

## 1. Criar o projeto Supabase

Crie um projeto em https://supabase.com/.

Depois abra o SQL Editor e execute todo o arquivo `supabase.sql`.

## 2. Configurar o app

Abra `index.html` e procure:

const CONFIG={
  url:"COLOQUE_SUA_SUPABASE_URL_AQUI",
  key:"COLOQUE_SUA_CHAVE_PUBLICAVEL_AQUI"
};

Substitua pelos dados do seu projeto.

Use a URL do projeto e a **Publishable key**. Não coloque uma `service_role`/secret key no navegador.

## 3. Configurar autenticação

No Supabase, deixe habilitado o login por e-mail e senha.

Se a confirmação de e-mail estiver habilitada, o usuário precisará confirmar o endereço antes de entrar.

## 4. Publicar

Você pode publicar esta pasta em Vercel, Netlify ou outro serviço de hospedagem estática.

O arquivo `index.html` é o aplicativo.

## 5. Compartilhar

1. Crie sua conta.
2. Crie uma casa.
3. O app exibirá um código de convite.
4. Outra pessoa cria a própria conta.
5. Ela informa o código.
6. Ambos passam a acessar o mesmo estoque.

## Segurança

A chave publicável pode aparecer no frontend. A segurança não deve depender de esconder essa chave. O banco usa RLS para permitir acesso somente aos membros da casa.

Nunca coloque uma `service_role` ou secret key dentro do `index.html`.
