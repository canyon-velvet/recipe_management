# 食谱管理 — Recipe Manager

One place for all the recipes I've saved, and a weekly meal plan that writes my grocery list for me.

https://github.com/user-attachments/assets/628aaba2-f09d-4c47-b458-a642517685ee



## The problem

My saved recipes were scattered everywhere: bookmarked cooking websites, posts saved on social
media, and several different recipe apps. When it was time to decide what to cook, I had to
remember where each one lived. When it was time to shop, I had to open every recipe and copy the
ingredients by hand.

I wanted one website that collects every recipe I care about and turns a week of meals into a
shopping list.

## What it does

- **Import a recipe from a link.** Paste a link to a recipe site such as 下厨房, or paste the
  recipe's text. It's read in the background, and Claude tidies it up: ingredients split into
  amounts and units, steps in order, tags and the author's tips. It then waits in a Draft box
  until I review and save it. I can also type a recipe in by hand.
- **Browse my collection.** Tag recipes by meal, cuisine, diet and convenience, then browse them
  from a category sidebar or search by name.
- **Plan the week.** Drop recipes into breakfast, lunch, dinner or snack for each day.
- **Get the grocery list for free.** Ingredients from the week's meals are gathered into one
  list, grouped by store aisle in shopping order. I can rename, reorder and add aisles.
- **Skip what I already have.** Mark items I already have at home, and they stay marked
  even when the meal plan changes.

## What's next

Next, I plan to add an **AI chat assistant** that suggests recipes based on my preferences and
requirements, so I can just ask for what I feel like cooking.

## A note on language

The interface is in Simplified Chinese. I built this for my own household, where we cook
from both Chinese and American recipes.

Built with Ruby on Rails.
