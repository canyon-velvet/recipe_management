## Project Overview
This is a Ruby on Rails recipe management system for home use. Follow these guidelines strictly to maintain code quality and consistency.

## Code Style & Conventions

### General Principles
1. Follow Ruby on Rails conventions and idioms
2. Keep code DRY (Don't Repeat Yourself) - always extract repeated patterns
3. Prefer simplicity and readability over cleverness
4. Use meaningful variable and method names that reveal intent
5. Keep methods small and focused on a single responsibility

### Ruby Style
- Use 2 spaces for indentation (not tabs)
- Use snake_case for methods and variables
- Use CamelCase for classes and modules
- Keep lines under 120 characters
- Use Ruby 3+ syntax features (e.g., endless methods, pattern matching when appropriate)
- Prefer `&&` and `||` over `and` and `or`
- Use explicit `return` only when returning early

### Rails-Specific Conventions
- Fat models, skinny controllers - business logic belongs in models or service objects
- Use service objects for complex business logic (e.g., `GroceryListUpdateService`)
- Use concerns for shared model behavior
- Name service objects with verb phrases (e.g., `UpdateGroceryList`, not `GroceryListUpdater`)
- Use `before_action` filters in controllers for common setup
- Prefer scopes over class methods in models for chainable queries

## Frontend Architecture

### Views & Partials
- **Keep view files short and clean** - extract partials aggressively
- Store reusable partials in `app/views/shared/` directory
- Use partials for any HTML block that:
  - Appears in multiple places
  - Exceeds 20-30 lines
  - Represents a distinct UI component
- Name partials with leading underscore: `_form.html.erb`, `_recipe_card.html.erb`
- Pass explicit local variables to partials rather than relying on instance variables

### CSS with Tailwind
- Use Tailwind utility classes as the primary styling approach
- **Extract repeated Tailwind patterns into custom CSS classes**
- Define custom classes in `app/assets/stylesheets/application.tailwind.css`
- Use `@apply` directive for custom classes:
```css
  .btn-primary {
    @apply bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700;
  }
```
- Group related custom classes together with comments
- Avoid inline styles - use Tailwind classes or custom classes
- Use Tailwind's configuration for project-specific colors/spacing

### JavaScript with Hotwire
- **Prefer Turbo over full page reloads** for navigation and form submissions
- Use Turbo Frames for independent page sections that update separately
- Use Turbo Streams for real-time updates (e.g., adding recipes to meal plan grid)
- **Use Stimulus controllers for client-side interactivity**:
  - Keep Stimulus controllers small and focused
  - Store controllers in `app/javascript/controllers/`
  - Use data attributes to connect HTML to Stimulus
  - Name controllers with descriptive nouns (e.g., `dropdown_controller.js`, `search_controller.js`)
- Avoid jQuery or other heavy JavaScript frameworks

## Backend Architecture

### Controllers
- Keep controller actions thin - delegate to models/services
- Follow RESTful conventions (index, show, new, create, edit, update, destroy)
- Use strong parameters for mass assignment protection
- **Extract common controller logic:**
  - Shared before_action filters
  - Common response patterns (e.g., error handling)
  - Move to `ApplicationController` or concerns
- Return appropriate HTTP status codes
- Use `respond_to` blocks for format handling when needed

### Models
- Use validations extensively to maintain data integrity
- **Extract repeated validation patterns into custom validators** in `app/validators/`
- Use callbacks sparingly and document their purpose
- **Extract complex queries to scopes** for reusability
- Use `accepts_nested_attributes_for` for forms with associations
- **Extract shared model behavior into concerns** in `app/models/concerns/`
- Keep callbacks simple or delegate to service objects

### Service Objects
- Use for complex business logic that doesn't belong in a single model
- Store in `app/services/` directory
- Name with verb phrases ending in "Service" (e.g., `GroceryListUpdateService`)
- Follow single responsibility principle
- Make testable with clear inputs and outputs
- Structure:
```ruby
  class ServiceName
    def initialize(dependencies)
      # setup
    end
    
    def call
      # main logic
    end
    
    private
    
    # helper methods
  end
```

### Database
- Use migrations for all schema changes
- Add appropriate indexes for foreign keys and frequently queried columns
- Use database constraints (unique indexes, foreign keys) to enforce data integrity
- Write reversible migrations when possible
- Use `change` method instead of `up`/`down` when Rails can auto-reverse

## Testing (When Implemented)
- Write tests for all models, controllers, and services
- Use RSpec for testing
- Follow AAA pattern (Arrange, Act, Assert)
- Use FactoryBot for test data
- Test edge cases and error conditions
- Keep tests DRY - extract common setup to shared contexts

## File Organization

### Extract Repeated Code To:
- `app/views/shared/` - reusable partials
- `app/models/concerns/` - shared model behavior
- `app/controllers/concerns/` - shared controller behavior
- `app/services/` - complex business logic
- `app/helpers/` - view helper methods (use sparingly, prefer decorators/presenters)
- `app/validators/` - custom validation classes
- `app/javascript/controllers/` - Stimulus controllers
- `app/assets/stylesheets/components/` - component-specific custom CSS classes

## Naming Conventions
- Controllers: plural, noun-based (e.g., `RecipesController`, `MealPlansController`)
- Models: singular, noun-based (e.g., `Recipe`, `MealPlan`)
- Services: verb-phrase + "Service" (e.g., `UpdateGroceryListService`)
- Partials: underscore prefix + descriptive name (e.g., `_recipe_form.html.erb`)
- Stimulus controllers: lowercase with underscores (e.g., `meal_plan_grid_controller.js`)
- CSS classes: kebab-case (e.g., `.recipe-card`, `.btn-primary`)

## Performance Considerations
- Use `includes` or `preload` to avoid N+1 queries
- Add database indexes for foreign keys and frequently searched columns
- Use counter caches for frequently counted associations
- Lazy load images when appropriate
- Use Turbo for partial page updates instead of full reloads

## Security
- Never trust user input - always use strong parameters
- Use `has_secure_password` for authentication
- Validate and sanitize all user-provided data
- Use Rails' built-in CSRF protection
- Scope queries by current_user to prevent unauthorized access
- Use `dependent: :destroy` carefully - consider data retention needs

## Comments & Documentation
- Write self-documenting code with clear names
- Add comments only when "why" isn't obvious from the code
- Document complex business logic
- Add schema comments to models with `annotate` gem
- Document public API methods in services

## Git Practices
- Write clear, descriptive commit messages
- Make small, focused commits
- Use feature branches for new functionality
- Don't commit commented-out code - use git history instead

## When in Doubt
- Prefer Rails conventions over custom solutions
- Check Rails Guides for best practices
- Keep it simple - add complexity only when needed
- Ask for clarification if requirements are unclear