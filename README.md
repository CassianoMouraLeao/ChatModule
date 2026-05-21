# ChatModule

A SwiftUI chat interface that talks to multiple LLM providers from a single,
unified UI. Built as part of my **iOS portfolio** to showcase modern SwiftUI,
Swift Concurrency and clean architecture.

> 🇧🇷 Versão em português logo abaixo ↓

---

## 🇬🇧 English

### What it is

A standalone iOS app showing how to wire up a polished chat UI to real LLMs.
Two providers are wired in:

| Provider | Backend                    | Model              | Cost  |
| -------- | -------------------------- | ------------------ | ----- |
| Google   | Firebase AI Logic          | Gemini 2.5 Flash   | Free  |
| OpenAI   | GitHub Models (URLSession) | GPT-4o-mini        | Free  |

Switch between them by tapping the chips on the hero header.

### Tech stack

- **SwiftUI** + **MVVM** with the modern `@Observable` macro (no Combine /
  `ObservableObject`)
- **Swift Concurrency** (`async`/`await`, actor isolation), tuned for
  Xcode 26's *Approachable Concurrency*
- **URLSession + Codable** for the OpenAI client (no third-party SDK)
- **Firebase AI Logic** for Gemini, **Firebase Remote Config** for secrets
- **XCTest + XCUITest** — 48 unit tests + 13 UI tests

### Highlights

- Hero header that bleeds under the status bar and stays put when the
  keyboard opens
- Animated typing indicator, suggestion cards, scroll-to-bottom button
- Tap-anywhere or swipe-down to dismiss the keyboard
- Tokens stored in **Firebase Remote Config** — never in source or in the
  app bundle. Rotate keys without rebuilding.

### Run it

1. Clone the repo
2. Open `ChatModule.xcodeproj` in Xcode 26+
3. Add your own `GoogleService-Info.plist` to `ChatModule/` (Firebase project
   with **AI Logic** enabled)
4. In Firebase Console → **Remote Config**, add a String parameter
   `GITHUB_MODELS_TOKEN` with a GitHub PAT (scope `models:read`) and publish
5. `⌘R` — done

### Tests

```bash
xcodebuild test \
  -project ChatModule.xcodeproj \
  -scheme ChatModule \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or `⌘U` in Xcode.

---

## 🇧🇷 Português

### O que é

App iOS standalone mostrando como integrar uma UI de chat bonita com LLMs
reais. Dois providers já estão prontos:

| Provider | Backend                    | Modelo             | Custo  |
| -------- | -------------------------- | ------------------ | ------ |
| Google   | Firebase AI Logic          | Gemini 2.5 Flash   | Grátis |
| OpenAI   | GitHub Models (URLSession) | GPT-4o-mini        | Grátis |

Você troca entre eles tocando nos chips do header.

### Stack

- **SwiftUI** + **MVVM** com o macro `@Observable` moderno (sem Combine /
  `ObservableObject`)
- **Swift Concurrency** (`async`/`await`, actor isolation), ajustado pra
  *Approachable Concurrency* do Xcode 26
- **URLSession + Codable** no cliente OpenAI (sem SDK de terceiro)
- **Firebase AI Logic** pro Gemini, **Firebase Remote Config** pros tokens
- **XCTest + XCUITest** — 48 testes unitários + 13 testes de UI

### Destaques

- Hero header que vai até a status bar e fica fixo quando o teclado abre
- Typing indicator animado, cards de sugestão, botão de scroll-to-bottom
- Tap em qualquer lugar (ou swipe pra baixo) fecha o teclado
- Tokens guardados no **Firebase Remote Config** — nunca no código nem no
  bundle. Rotacionar a chave não exige novo build.

### Como rodar

1. Clona o repo
2. Abre `ChatModule.xcodeproj` no Xcode 26+
3. Coloca seu próprio `GoogleService-Info.plist` em `ChatModule/`
   (projeto Firebase com **AI Logic** habilitado)
4. No Firebase Console → **Remote Config**, adiciona um parâmetro String
   `GITHUB_MODELS_TOKEN` com um GitHub PAT (escopo `models:read`) e publica
5. `⌘R` — pronto

### Testes

```bash
xcodebuild test \
  -project ChatModule.xcodeproj \
  -scheme ChatModule \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Ou `⌘U` no Xcode.

---

> Made for portfolio purposes by **Cassiano Leão** · iOS Engineer
