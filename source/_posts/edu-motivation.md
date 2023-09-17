---
title: Earth OL | Learning is a worth-playing game
date: 2023-09-14 10:28:56
tags:
- Gaming
- Earth OL
---

Learning is an other-worldly designed game. I classify learning as a game, because it features the following:

- ??? (Most important feature, but usually ignored, I'll reveal it later)
- Rules: you cheat, you take corresponding risks
- Challenge: a lot of subjects are tough to learn
- Feedback: a test reveals your rank among your classmates
- Interactivity: you learn, you (optionally) gain
- Conflict: your opponents get higher rank, you get lower
- Engagement: you enjoy graphics effects (scholarship and etc.) for high rk
- Progression: you can't learn AI before learning Calculus
- Randomness: your rk sometimes falls even if you learn hard
- Social: you can choose to learn with your roommate or classmate
- Theme: high-quality and realistic graphics, surpassing *all* digital games

However, without the first one, learning is equivalent to imprisonment, far from a worth-playing game.

The first feature is Motivation.

## Characteristics

Motivation is essential to *any* human being, but in different ways. Imagine you're asked to learn some Math, you may be excited to know:

- Option 1: how Math can help you make an AI
- Option 2: how Math can explain things inner-consistently

There's already decent practices of utilizing motivation. For example, a college course changed its name from "Linear Algebra" to "Foundations of Machine Learning", attracting lots of option-1 people.

Sadly, in about 90% of educational practices, motivation is neglected. As learners, there are strategies we can utilize to find the motivation we need.

Before we move on, let's identify some common misconceptions about motivation.

## Misconceptions

### Motivation is eternal and static

*Anything* depends on its time and space, motivation is not an exception. For example, my algorithm teacher repeats examples where someone makes tremendous profit from algorithms, but this motivation doesn't apply for most of us, because it seems too unreal (and middle-aged). 

In my opinion, a motivation like "making your own programming language in 143 lines" can really attract some option-1 people. It satisfies the following conditions:

- Achievable: 143 lines doesn't seem like a too-large number
- Fresh: you can rarely see a tutorial of making your own programming language
- Expandable: you see possibilities customizing the programming language

The money motivation only satisfies condition "Expandable".

### Motivation works the same for everyone

Some teachers tend to make assumptions for *everyone*. For example, a teacher of mine assumes that all students want a higher rank, which is clearly a false assumption.

In fact, making a motivation that attracts all people is *impossible*.

When teaching, it's better to come up with a motivation that attracts about 30% of people, and stick with your motivation. Wasting the time of the remaining 70% of people is exceptionally unethical and inefficient.

When self-learning, you would prefer a motivation that's specially tailored for yourself, as it can generally be more specific than a educational-purpose motivation. Having a custom motivation that you'll strive for during your *whole life*, is both more difficult and more powerful than it seems.

## Find your own motivation

Nowadays, high-quality educational resources are publicly avaliable, with possibly only one imperfection caused by the misconceptions above: They lack a good motivation. Solving the imperfection can theoretically greatly improve your learning capabilities (if you want to).

Assume you're to learn Probability Theory.

### Ask ChatGPT

An example prompt is:

> What practical project can I make after learning Probability Theory? I already learnt Python, please avoid involving new prerequisites in the project.

ChatGPT replies:

> After learning Probability Theory and having Python skills, there are several practical projects you can undertake to apply your knowledge. Here are a few project ideas that don't require new prerequisites:
> 
> - Dice Roll Simulator: Create a Python program that simulates rolling dice. You can calculate and visualize the probabilities of different outcomes for various types of dice, such as 6-sided, 10-sided, or even customized dice.
> 
> - Coin Toss Probability Calculator: Build a tool that calculates the probabilities of getting heads or tails when flipping a coin a certain number of times. You can also add features to simulate multiple coin flips and visualize the outcomes.
> 
> - Card Game Simulator: Develop a program that simulates card games like Poker or Blackjack. You can use probability theory to calculate the odds of winning or achieving specific hands. Implement a simple AI opponent for added complexity.
>
> - Monte Carlo Simulation: Use Monte Carlo simulations to estimate probabilities in various scenarios. For example, you can estimate the value of π by simulating random points within a circle inscribed in a square.
>
> - Stock Price Prediction: Apply probability theory to model and predict stock price movements. You can use historical data and methods like Brownian motion to create a basic stock price prediction model.
> 
> - Weather Forecasting: Build a simple weather forecasting tool that uses historical weather data and probability distributions to make short-term weather predictions for a specific location.
>
> - Game of Chance: Create a simple game of chance, such as a casino-style game, and calculate the house edge and expected outcomes for players. This project will involve probability calculations for various game scenarios.
>
> - Random Password Generator: Develop a password generator that creates secure and random passwords based on user-defined parameters. You can use probability distributions to ensure password randomness.
>
> - A/B Testing Analysis: Analyze the results of an A/B test using probability theory. Calculate statistical significance and confidence intervals to determine the effectiveness of changes made to a website or application.
>
> - Sports Statistics Analyzer: Analyze sports statistics and apply probability theory to predict the outcomes of sports events. You can create a tool that provides win-loss predictions for upcoming games based on historical data.
> 
> These projects will help you reinforce your understanding of probability theory while applying your Python skills to real-world scenarios. Choose a project that interests you the most and aligns with your goals and preferences.

You can look for a interesting one among them. Once found, you can ask ChatGPT for more details.

For example, Card Game Simulator intrigued me. To get a grasp of how it would work, you can ask:

> I'm particularly interested in Card Game Simulator. How can I build a minimal version of it, and what probability knowledge will it involve?

ChatGPT replied with a lot of code, but it's solely a simulator, not a predictor using knowledge from Probability Theory. You can correct that with:

> How can I implement a predicting model? Please annotate the probability knowledge used.

ChatGPT gave some code, the related part is:

```python
def basic_strategy_predict(player_hand, dealer_upcard):
    # Basic strategy: Make decisions (hit or stand) based on the player's hand and the dealer's upcard.
    
    player_value = calculate_hand_value(player_hand)
    
    # Probability knowledge: The likelihood of busting when hitting
    # If the player's hand value is 11 or less, it's always safe to hit.
    if player_value <= 11:
        return 'hit'
    
    # If the player's hand value is 12 to 16 and the dealer's upcard is 7 or higher,
    # hitting is the safer choice because the player's chances of beating the dealer are low.
    if 12 <= player_value <= 16 and dealer_upcard in ['7', '8', '9', '10', 'Ace']:
        return 'hit'
    
    # If the player's hand value is 17 or higher, standing is generally the safer choice.
    return 'stand'
```

This seems too naive. You want some Probability Theory that you've never learnt. You can ask:

> Can you implement something that uses advanced probability knowledge? Some calculus is preferred.

ChatGPT replies:

> Implementing a card game predictor that uses more advanced probability knowledge, particularly involving calculus, can be quite challenging. While the basic strategy model we discussed earlier is suitable for most practical purposes, incorporating advanced calculus-based probabilities can be an overkill for a game like Blackjack. However, I can introduce you to a concept called "card counting," which involves tracking the composition of the remaining deck to make more informed decisions. This method doesn't directly use calculus but relies on statistical probability concepts.
>
> ...

This means the conversation is busted. You can retry your prompts until you get a good answer.

However, you can feel how the process can be irritating. Below is a better way.

### Ask Others

Apparently lots of people have learnt Probability Theory, and ultimately found it useful. You can ask some people what their life would be without Probability Theory, which will give you results more accurate and realistic than ChatGPT.

The method is harder to implement than the previous one, so no examples are provided here. I want to introduce the best way that I can think of, in the next section.

### Foreseeing

Simply, you just try to implement things beyond your capabilities, check what knowledge is missing, and fill it. 

This seeming-naive technique can stunningly *solve* the motivation problem! That's because in traditional learning, you define what to learn first, and then what to create. When forseeing, you define what you want to create first, and then what to learn!

What's stopping most people from implementing this method is its toughness. Most people would prefer an *actual* teacher to teach them something, because in self-automated learning there's less learning material and weaker disciplinary mechanism.

I'm working on [Silent-Lang](https://github.com/5eqn/silent-lang) to make Competitive Programming more intuitive and accessible, but it takes time to achieve. Currently it's factual that self-automated learning is difficult and not achievable for anyone, so there's no silver bullet for the motivation problem.

## Conclusion

With the motivation problem solved in any of the above ways, learning can become a worth-playing game. At the present, you might have to solve it yourselves, but it would be much better if motivation is accessible by *everyone*.
