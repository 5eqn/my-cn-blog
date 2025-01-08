---
title: Iced 框架初体验
date: 2023-06-21 17:24:35
tags:
- 编程
- 前端
---

Iced 是一个 Rust 语言下的前端框架。目前而言，Rust 生态里面的 Diesel ORM 我觉得远不如 GORM，SeaORM 准备了解，但 Rocket 远超 Gin，不清楚 Iced 框架怎么样。不过 Iced 首先在能跨的平台种类上就不是很多，Web 构建非常不方便（理论上可以搞一个 CLI Tool），只能跨 Win / Linux / Mac. 但这玩意可是用来做 2D 游戏引擎的啊！应该会很强吧！

## 插入

在调试网络环境的时候遇到 curl 能通直接连通不了的问题，原因是 DNS 配置有误，以后可以参考。

## 和 Yew 对比

之前有考虑过使用 Yew 框架，但 Yew 很多地方还是 HTML 那套思路，看起来乱七八糟的。以计数器为例，先看看 Yew 的。我将注释出所有我认为需要注意的地方。

```rust
use gloo::console;
use yew::{html, Component, Context, Html};

pub enum Msg {
    Increment,
    Decrement,
}

pub struct App {
    value: i64,
}

impl Component for App {
    type Message = Msg;
    type Properties = ();

    fn create(_ctx: &Context<Self>) -> Self { // 组件传参
        Self { value: 0 }
    }

    fn update(&mut self, _ctx: &Context<Self>, msg: Self::Message) -> bool {
        match msg {
            Msg::Increment => {
                self.value += 1;
                true // 这里需要专门返回 true 表示要更新
            }
            Msg::Decrement => {
                self.value -= 1;
                true
            }
        }
    }

    fn view(&self, ctx: &Context<Self>) -> Html {
        html! {
            <div>
                <div class="panel">
                    // HTML 的格式太过复杂，而且要用相同的文本括回去
                    <button class="button" onclick={ctx.link().callback(|_| Msg::Increment)}> 
                        { "+1" }
                    </button>
                    <button onclick={ctx.link().callback(|_| Msg::Decrement)}>
                        { "-1" }
                    </button>
                </div>
                <p class="counter">
                    { self.value }
                </p>
            </div>
        }
    }
}

fn main() {
    yew::Renderer::<App>::new().render();
}
```

Iced 则精简不少：

```rust
use iced::widget::{button, column, text};
use iced::{Alignment, Element, Sandbox, Settings};

pub fn main() -> iced::Result {
    Counter::run(Settings::default())
}

struct Counter {
    value: i32,
}

#[derive(Debug, Clone, Copy)] // 这里要多 derive 一些东西
enum Message {
    IncrementPressed,
    DecrementPressed,
}

impl Sandbox for Counter {
    type Message = Message;

    fn new() -> Self { // 参数比较干净
        Self { value: 0 }
    }

    fn title(&self) -> String {
        String::from("Counter - Iced") // 这里感觉 title 和 view 耦合不太理想
    }

    fn update(&mut self, message: Message) {
        match message {
            Message::IncrementPressed => {
                self.value += 1; // 不需要返回值，更干净
            }
            Message::DecrementPressed => {
                self.value -= 1;
            }
        }
    }

    fn view(&self) -> Element<Message> {
        // 相当好看的菊花链语法
        column![
            button("Increment").on_press(Message::IncrementPressed),
            text(self.value).size(50),
            button("Decrement").on_press(Message::DecrementPressed)
        ]
        .padding(20)
        .align_items(Alignment::Center)
        .into()
    }
}
```

不过因为要限定 Message 的可能性，实际上写起来会比 Vue 在这方面内容多点，优势主要在于元件比较符合直觉。顺带一提这里返回 `Element<Message>` 实际上已经把 `Element` 视为 Monad！

## 中型实例分析：Game of Life

看看 Ices 的组件传参机制：

```rust
pub fn new<F>(label: impl Into<String>, is_checked: bool, f: F) -> Self
where
    F: 'a + Fn(bool) -> Message,
{
    Checkbox {
        is_checked,
        on_toggle: Box::new(f),
        label: label.into(),
        width: Length::Shrink,
        size: Self::DEFAULT_SIZE,
        spacing: Self::DEFAULT_SPACING,
        text_size: None,
        text_line_height: text::LineHeight::default(),
        text_shaping: text::Shaping::Basic,
        font: None,
        icon: Icon {
            font: Renderer::ICON_FONT,
            code_point: Renderer::CHECKMARK_ICON,
            size: None,
            line_height: text::LineHeight::default(),
            shaping: text::Shaping::Basic,
        },
        style: Default::default(),
    }
}
```

注意这里的 new 纯粹只是一个数据结构，需要和 Application trait 里面有个强制带 flags 的 new 区别开。

使用 Message 有个很逆天的好处就是不需要像 React 一样把回调函数传给子组件，不需要像 Vue 混淆 getter 和 setter，也不需要单独的全局状态管理插件！我现在才发现！而且这样的话更符合我「产生什么实例就做什么事」的编程观，不过实际上是同构的。

正常的编程语言搞带参数的 enum 特别困难，所以实现这种 Message 制度有障碍。但在 Rust 里面，这个问题直接瞬间得到解决：

```rust
#[derive(Debug, Clone)]
enum Message {
    Grid(grid::Message, usize),
    Tick(Instant),
    TogglePlayback,
    ToggleGrid(bool),
    Next,
    Clear,
    SpeedChanged(f32),
    PresetPicked(Preset),
}
```

Rust 作为我心目中最好的 C-like 语言，已经有一种 Idris2 平替的感觉了！

## 函数式的影子

看，甚至还有 Functor：

```rust
let content = column![
    self.grid
        .view()
        .map(move |message| Message::Grid(message, version)),
    controls,
];
```

注意 `canvas::Program<Message>` trait 中的一个函数：

```rust
fn update(
    &self,
    _state: &mut Self::State,
    _event: Event,
    _bounds: Rectangle,
    _cursor: mouse::Cursor,
) -> (event::Status, Option<Message>) {
    (event::Status::Ignored, None)
}
```

注意它返回 Message，因此从 Canvas 的实例可以构造出一个 `Element<Message>`：

```rust
pub fn view(&self) -> Element<Message> {
    Canvas::new(self)
        .width(Length::Fill)
        .height(Length::Fill)
        .into()
}
```

具体解释了前面提到的 Element 是 Monad. 有 Monad 就有回合制，这里回合的一方是前端设计顶层，只摆出有哪些组件（其返回什么信息什么是未知的），接收到组件返回的信息后再更新自己的状态，这里的 Monad 借助了组件状态来实现，实际上和正常的 Monad 是同构的，也更方便没有函数式编程基础的人理解；回合的另一方是底层组件，在收到具体的用户请求的时候再去生成 Message, 不需要管这个 Message 被如何处理。

相比之下，Vue、React 这种框架需要自己把 setter 往下传，就显得很小丑。私以为 Iced 这种才是合格的解耦。

## Affine Types

在 Affine Types 的加持下，处理状态更新的时候我们可以更准确地对内存建模：

```rust
Message::Tick(_) | Message::Next => {
    self.queued_ticks = (self.queued_ticks + 1).min(self.speed);

    if let Some(task) = self.grid.tick(self.queued_ticks) {
        if let Some(speed) = self.next_speed.take() {
            self.speed = speed;
        }

        self.queued_ticks = 0;

        let version = self.version;

        return Command::perform(task, move |message| {
            Message::Grid(message, version)
        });
    }
}
```

注意我们通过 Command::perform 执行了一个异步函数 task，首先这个 task 因为是 Affine 的不会被疯狂执行；take 函数某种意义上只是个压行，不能体现出 Affine Types 的好处；perform 的 callback 里面有个 move 标签，可以以最高效的方式使用内存，虽然省下来一点用都没有，但写这种程序的时候可以有浓浓的正义感，说 Rust 是编程语言的「原神」一点都不为过。

## 结语

以后有机会分析 Canvas 的绘制机制和用户输入的处理机制，等到需要写自己后端了还可以学 SeaORM 和 GraphQL!

Rewrite Everything in Rust!
