CLAUDE.md: Chatwoot Development Guidelines
==========================================

This file provides comprehensive guidance for development, coding standards, architecture, and testing within the Chatwoot repository.

1\. Development Commands
------------------------

This section lists the essential commands for setting up, running, testing, and linting the application.

### Setup and Running

**Purpose**

**Command**

**Setup**

`bundle install && pnpm install`

**Run Dev**

`pnpm dev` or `overmind start -f ./Procfile.dev`

**Run Project**

`overmind start -f Procfile.dev`

### Linting and Testing

**Purpose**

**Command**

**Lint JS/Vue**

`pnpm eslint` / `pnpm eslint:fix`

**Lint Ruby**

`bundle exec rubocop -a`

**Test JS**

`pnpm test` or `pnpm test:watch`

**Test Ruby**

`bundle exec rspec spec/path/to/file_spec.rb`

**Single Test**

`bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`

2\. Code Style and Best Practices
---------------------------------

### General Style

*   **Ruby**: Follow **RuboCop** rules (150 character max line length). Use compact `module/class` definitions; avoid nested styles.
    
*   **Vue/JS**: Use **ESLint** (Airbnb base + Vue 3 recommended).
    
*   **Naming**: Use clear, descriptive names with consistent casing.
    
*   **Type Safety**: Use **PropTypes** in Vue, **strong params** in Rails.
    
*   **I18n**: No bare strings in templates; use i18n (Translations should only update `en.yml` for Backend and `en.json` for Frontend).
    
*   **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`).
    
*   **Models**: Validate presence/uniqueness, add proper indexes.
    

### Vue/JS Specific

*   **Vue Components**: Use **PascalCase**.
    
*   **Events**: Use **camelCase**.
    
*   **Vue API**: Always use **Composition API** with `<script setup>` at the top.
    

3\. Front-end Styling and Design
--------------------------------

### Styling (Tailwind Only)

*   **Do not write custom CSS**.
    
*   **Do not use scoped CSS**.
    
*   **Do not use inline styles**.
    
*   Always use **Tailwind utility classes**.
    
*   **Colors**: Refer to `tailwind.config.js` for color definitions.
    
*   **Frontend**: Use `components-next/` for new message bubbles (the rest is being deprecated).
    

### Visual Development & Testing (Mandatory for FE Changes)

The project follows S-Tier SaaS design standards. **IMMEDIATELY after implementing any front-end change**, perform this **Quick Visual Check**:

1.  **Identify what changed** - Review the modified components/pages.
    
2.  **Navigate to affected pages** - Use Playwright commands (e.g., `mcp__playwright__browser_navigate`).
    
3.  **Verify design compliance** - Compare against `/context/design-principles.md`.
    
4.  **Validate feature implementation** - Ensure the change fulfills the user's specific request.
    
5.  **Check for errors** - Run `mcp__playwright__browser_console_messages()` ⚠️.
    

### Design Compliance Checklist

When implementing UI features, verify:

*   **Visual Hierarchy**: Clear focus flow, appropriate spacing.
    
*   **Consistency**: Uses design tokens, follows patterns.
    
*   **Responsiveness**: Works on mobile (375px), tablet (768px), desktop (1440px).
    
*   **Accessibility**: Keyboard navigable, proper contrast, semantic HTML.
    
*   **Error Handling**: Clear error states, helpful messages.
    

4\. General Guidelines
----------------------

*   **MVP focus**: Least code change, happy-path only.
    
*   **Break down complex tasks** into small, testable units.
    
*   **Iterate after confirmation**.
    
*   **Remove dead/unreachable/unused code**.
    
*   Don’t write multiple versions or backups for the same logic — pick the best approach and implement it.
    
*   **Don't reference Claude in commit messages.**
    

5\. Enterprise Edition Notes (Critical)
---------------------------------------

*   Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
    
*   When you add or modify core functionality, always check for corresponding files in `enterprise/` and **keep behavior compatible**.
    
*   Follow the Enterprise development practices documented here:
    
    *   `https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38`
        

### Practical Checklist for Changes to Core Logic

*   **Search for related files** in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
    
*   If adding new endpoints, services, or models, consider whether Enterprise needs:
    
    *   An override (e.g., `enterprise/app/...`), or
        
    *   An **extension point** (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
        
*   Avoid **hardcoding** instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
    
*   **Tests**: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.