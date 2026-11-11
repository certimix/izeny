# 𝗜𝓩𝓮𝓷𝔂 - Rede Social, Comunidade & Suporte ZenyDesk

Rede social, mensageria e comunidade oficial do ecossistema **ZenyDesk**, projetada para conectar técnicos, clientes, empresas e parceiros em um ambiente moderno, ágil e em tempo real.

Disponível para uso direto no navegador (**Web**) e aplicativo nativo (**Android**):
* **Web**: [https://izeny.zenydesk.com/](https://izeny.zenydesk.com/)
* **Painel de Moderação / Backend**: [https://izeny.zenydesk.com/_/](https://izeny.zenydesk.com/_/)
* **Download APK Android**: [https://izeny.zenydesk.com/downloads/IZeny.apk](https://izeny.zenydesk.com/downloads/IZeny.apk)

---

## 🏛️ Arquitetura do Sistema

```
                      +-----------------------------+
                      |       Clientes & Usuários   |
                      +--------------+--------------+
                                     |
               +---------------------+---------------------+
               |                                           |
        [ Flutter Web ]                            [ Flutter Android ]
    (izeny.zenydesk.com)                              (IZeny.apk)
               |                                           |
               +---------------------+---------------------+
                                     |  HTTPS / WSS / REST
                                     v
                      +-----------------------------+
                      |         Nginx (VPS)         |
                      |   Proxy Reverso & SSL Let's |
                      +--------------+--------------+
                                     |
               +---------------------+---------------------+
               |                                           |
               v                                           v
    [ PocketBase Backend ]                      [ IZeny Auth Service ]
    (Porta 8090 - SQLite + SSE)                 (Porta 8095 - Node.js)
    - Coleções: users, posts,                   - Google OAuth 2.0 GIS
      comments, chats, messages,                - Redefinição de Senha
      likes, follows, notifications             - Integração Superuser
```

---

## 📱 Recursos e Módulos Principais

### 1. Feed e Networking (Inspirado em 3 Colunas)
* **Barra Lateral Esquerda**: Logomarca oficial transparente, navegação rápida entre Feed, Mensagens, Buscar, Notificações e Perfil.
* **Feed Central**: Criação de publicações com texto, fotos e vídeos. Suporte a curtidas e comentários em tempo real.
* **Painel Lateral Direito**: Acesso rápido a técnicos parceiros e links diretos para os módulos do ecossistema ZenyDesk (ZenyDesk O.S., ZenyDesk ERP, etc.).

### 2. Módulo de Mensageria em Tempo Real
* Bate-papo privativo entre técnicos e clientes.
* Envio de mensagens de texto, imagens e gravações de áudio/voz.
* Player de áudio embutido diretamente nos balões de chat.

### 3. Autenticação e Segurança
* **E-mail e Senha**: Validação defensiva com mensagens em português e foco em usabilidade.
* **Google OAuth 2.0**: Botão oficial no padrão visual Google Identity Services.
* **Redefinição de Senha Segura**: Modal interativo que atualiza as credenciais diretamente no banco com validação de força.
* **Multilíngue Nativo**: Suporte imediato a Português (🇧🇷), Inglês (🇺🇸) e Espanhol (🇪🇸).

---

## 🚀 Compilação e Deploy Contínuo (CI/CD)

Todo o processo de build é automatizado via **GitHub Actions** em ambiente isolado de nuvem:

1. **Commit na branch `main`**: Dispara automaticamente o pipeline de compilação.
2. **Flutter 3.0.5**: Compila a versão Web otimizada e o pacote Android Release (`IZeny.apk`).
3. **GitHub Releases**: Gera a tag versionada (`v1.0.X`) com os binários anexados.
4. **Deploy na VPS**: O script `/tmp/deploy_izeny_v15.sh` extrai os assets em `/var/www/izeny/web/` e disponibiliza o APK para download público com permissões seguras `www-data`.

---

## 🛡️ Desenvolvimento & Governança

* **Ecossistema**: ZenyDesk
* **Autoria Técnica**: [AORDIC.COM.BR](https://aordic.com.br)
