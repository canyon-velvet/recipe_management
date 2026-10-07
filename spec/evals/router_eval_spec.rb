require "rails_helper"
require_relative "reply_transcript"

# Live eval of the assistant's router. It sends each labelled message in router_cases.yml through the real assistant,
# with nothing stubbed: the router, then the specialist it hands over to. A case passes when the reply was written by
# the expected agent and the expected preferences were suggested.
#
# It prints the score with each case's result, and writes a log of every run (the chat, then each model and tool call)
# to log/evals/, to read when a case fails. A model's choices vary from run to run, so a miss doesn't fail the spec.
# It calls Claude, so it only runs when asked; otherwise it's left out of the run:
#
#   LIVE_ASSISTANT=1 bundle exec rspec spec/evals
#
# Imports it starts are only queued, so no pages are fetched. Everything it saves is rolled back with the test
# database.
RSpec.describe "Assistant router eval", if: ENV["LIVE_ASSISTANT"].present? do
  Result = Data.define(:number, :message, :passed, :routed, :notes, :transcript)

  cases = YAML.load_file(Rails.root.join("spec/evals/router_cases.yml"))
  results = []

  let(:user) { create(:user) }

  before do
    raise "LIVE_ASSISTANT needs an Anthropic API key (Rails credentials or ANTHROPIC_API_KEY)" unless
      CleanRecipeService.available?

    add_recipes
  end

  around do |example|
    queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = queue_adapter
  end

  after(:all) { report(results.sort_by(&:number)) if results.any? }

  cases.each.with_index(1) do |eval_case, number|
    it "#{number}. #{eval_case['message']}" do
      conversation = create(:conversation, user: user)
      eval_case.fetch("history", []).each do |who, text|
        if who == "user"
          conversation.messages.create!(role: :user, content: text)
        else
          conversation.messages.create!(role: :assistant, agent: who, content: text, status: :done)
        end
      end
      reply = conversation.ask(eval_case["message"]).last

      WriteReplyService.new(reply).call

      results << score(number, eval_case, reply.reload)
    end
  end

  # A small collection for Recommend to search: name, total minutes and ingredients.
  def add_recipes
    {
      "Tomato and egg stir-fry" => [ 15, [ "egg", "tomato", "scallion" ] ],
      "Shakshuka" => [ 25, [ "egg", "tomato", "bell pepper" ] ],
      "Mapo tofu" => [ 30, [ "tofu", "ground pork", "chili bean paste", "Sichuan peppercorn" ] ],
      "Chicken noodle soup" => [ 45, [ "chicken", "noodles", "carrot" ] ]
    }.each do |name, (minutes, ingredients)|
      recipe = build(:recipe, user: user, name: name, total_minutes: minutes, servings: 2)
      ingredients.each { |ingredient| recipe.recipe_ingredients.build(ingredient: ingredient_named(ingredient)) }
      recipe.save!
    end
  end

  def ingredient_named(name) = user.ingredients.find_by(name: name) || create(:ingredient, user: user, name: name)

  # Right when the expected agent wrote the reply, and every expected category was suggested (in any wording).
  def score(number, eval_case, reply)
    missing = eval_case.fetch("suggests", []) - reply.preference_suggestions.pluck("category")
    misses = []
    misses << "expected #{eval_case['expect']}" if reply.agent != eval_case["expect"]
    misses << "didn't suggest #{missing.join(', ')}" if missing.any?
    # Not a routing miss, but worth knowing.
    failure = "the reply failed: #{reply.run&.error}" if reply.failed?
    Result.new(number: number, message: eval_case["message"], passed: misses.empty?, routed: reply.agent,
               notes: [ *misses, failure ].compact, transcript: ReplyTranscript.new(reply).to_s)
  end

  def report(results)
    passed = results.count(&:passed)
    log = Rails.root.join("log/evals/router-#{Time.current.strftime('%Y%m%d-%H%M%S')}.md")
    FileUtils.mkdir_p(log.dirname)
    File.write(log, [ "# Router eval: #{passed}/#{results.size} passed", *results.map { log_entry(_1) } ].join("\n\n") + "\n")

    puts "\nRouter eval: #{passed}/#{results.size} passed"
    results.each { |result| puts "  #{summary(result)}" }
    puts "Log: #{log.relative_path_from(Rails.root)}"
  end

  # e.g. "FAIL 11. Is my import done yet? → router (expected import)"
  def summary(result)
    notes = " (#{result.notes.join('; ')})" if result.notes.any?
    "#{result.passed ? 'PASS' : 'FAIL'} #{result.number}. #{result.message.truncate(60)} → #{result.routed}#{notes}"
  end

  def log_entry(result) = "## #{summary(result)}\n\n#{result.transcript}"
end
