---
title: Iced 框架功能探索
date: 2023-06-22 10:37:14
tags:
- 编程
- 前端
---

在昨天初见 Iced 框架时，我发现其具有相当强的表达能力，并准备分析其复杂输入处理、复杂渲染的机制，并继续探索其他示例。

## 输入处理

注意这个函数签名：

```rust
fn update(
    &self,
    interaction: &mut Interaction,
    event: Event,
    bounds: Rectangle,
    cursor: mouse::Cursor,
) -> (event::Status, Option<Message>) {
```

这个函数把输入的事件、光标信息和自己的信息映射成对 event 的处理状态和可能出现的 Message，只是加了一个可变的状态，让这个函数有了一种有限状态机的感觉，这里利用 &mut 保证了其自身状态的线性。

可变的状态定义如下：

```rust
pub enum Interaction {
    None,
    Drawing,
    Erasing,
    Panning { translation: Vector, start: Point },
}
```

这时候再看对鼠标输入的处理就很直观了：

```rust
mouse::Event::ButtonPressed(button) => {
    let message = match button {
        mouse::Button::Left => {

            // 根据当前格子确定本次互动的状态，
            // 这样后面即使只收到 mouse::Event::CursorMoved 也知道干啥
            *interaction = if is_populated {
                Interaction::Erasing
            } else {
                Interaction::Drawing
            };

            // 顺带发个 Message
            populate.or(unpopulate)
        }
        mouse::Button::Right => {

            // 和上面同理
            *interaction = Interaction::Panning {
                translation: self.translation,
                start: cursor_position,
            };

            // 因为右键拖动是位移，只点一下没有意义，不发消息
            None
        }
        _ => None,
    };

    (event::Status::Captured, message)
}
mouse::Event::CursorMoved { .. } => {
    let message = match *interaction {

        // 根据预先确定好的「本次互动状态」决定发什么消息
        Interaction::Drawing => populate,
        Interaction::Erasing => unpopulate,
        Interaction::Panning { translation, start } => {
            Some(Message::Translated(
                translation
                    + (cursor_position - start)
                        * (1.0 / self.scaling),
            ))
        }
        _ => None,
    };

    // 发送输入处理状态，可能是为了防止被其他组件处理
    let event_status = match interaction {
        Interaction::None => event::Status::Ignored,
        _ => event::Status::Captured,
    };

    (event_status, message)
}
```

其状态也被用于确定鼠标光标的形状：

```rust
fn mouse_interaction(
    &self,
    interaction: &Interaction,
    bounds: Rectangle,
    cursor: mouse::Cursor,
) -> mouse::Interaction {
    match interaction {
        Interaction::Drawing => mouse::Interaction::Crosshair,
        Interaction::Erasing => mouse::Interaction::Crosshair,
        Interaction::Panning { .. } => mouse::Interaction::Grabbing,
        Interaction::None if cursor.is_over(bounds) => {
            mouse::Interaction::Crosshair
        }
        _ => mouse::Interaction::default(),
    }
}
```

## 渲染机制

首先看看 draw 的函数签名：

```rust
fn draw(
    &self,
    _interaction: &Interaction,
    renderer: &Renderer,
    _theme: &Theme,
    bounds: Rectangle,
    cursor: mouse::Cursor,
) -> Vec<Geometry> {
```

接受当前状态、渲染器类型（其实我觉得 renderer 不应该需要我们传）、当前主题以及自身信息的不可变借用，以及边界和光标信息，返回要绘制的内容。根据是否需要缓存有两种绘制思路，缓存式：

```rust
let life = self.life_cache.draw(renderer, bounds.size(), |frame| {
    let background = Path::rectangle(Point::ORIGIN, frame.size());
    frame.fill(&background, Color::from_rgb8(0x40, 0x44, 0x4B));

    frame.with_save(|frame| {
        frame.translate(center);
        frame.scale(self.scaling);
        frame.translate(self.translation);
        frame.scale(Cell::SIZE as f32);

        let region = self.visible_region(frame.size());

        for cell in region.cull(self.state.cells()) {
            frame.fill_rectangle(
                Point::new(cell.j as f32, cell.i as f32),
                Size::UNIT,
                Color::WHITE,
            );
        }
    });
});
```

注意使用了一个 self.life_cache.draw，但实际上就是一个限定只能查 bounds 的 useMemo，我觉得这个设计并不好。还有非缓存式：

```rust
let mut frame = Frame::new(renderer, bounds.size());

let hovered_cell = cursor.position_in(bounds).map(|position| {
    Cell::at(self.project(position, frame.size()))
});

if let Some(cell) = hovered_cell {
    frame.with_save(|frame| {
        frame.translate(center);
        frame.scale(self.scaling);
        frame.translate(self.translation);
        frame.scale(Cell::SIZE as f32);

        frame.fill_rectangle(
            Point::new(cell.j as f32, cell.i as f32),
            Size::UNIT,
            Color {
                a: 0.5,
                ..Color::BLACK
            },
        );
    });
}
```

可以看到非缓存式就是每次直接自己实例化一个 Frame，缓存式则先定义一个 cache，然后去调用其 draw 方法。

在具体渲染的时候有微妙的叠加顺序，先 scale 再 translate 和反过来是不一样的，但这就涉及一些傻逼数学了。这个框架没能对这种数学建模，我略有失望。

## 时序逻辑

Iced 里面有一个专用的用于注册随时间产生的状态的函数：

```rust
fn subscription(&self) -> Subscription<Message> {
    if self.is_playing {
        time::every(Duration::from_millis(1000 / self.speed as u64))
            .map(Message::Tick)
    } else {
        Subscription::none()
    }
}
```

虽然看上去有些多余，完全可以自己使用线程来写，但这实际上是一层封装：封装后可以直接描述「状态」本身，例如「每多少秒产生一次这个信息」，而不是直接每多少秒去产生这个信息，这种封装是可取的。注册之后就会连续地产生 Tick 事件。

 最终逻辑被传到 Life 中，这里用 Life 表示「活着的」格子：

```rust
fn tick(&mut self) {
    let mut adjacent_life = FxHashMap::default();

    for cell in &self.cells {
        let _ = adjacent_life.entry(*cell).or_insert(0);

        for neighbor in Cell::neighbors(*cell) {
            let amount = adjacent_life.entry(neighbor).or_insert(0);

            *amount += 1;
        }
    }

    for (cell, amount) in adjacent_life.iter() {
        match amount {
            2 => {}
            3 => {
                let _ = self.cells.insert(*cell);
            }
            _ => {
                let _ = self.cells.remove(cell);
            }
        }
    }
}
```

可以非常清晰地看到康威生命游戏的规则：格子周围有两个活着就维持自身状态，三个就变活，其他数量就挂掉。在 Iced 框架下可以非常清晰地把逻辑和 UI 框架解耦。UI 渲染结果只是核心数据结构的一个「镜像」，通过不可变引用的方式被固定的函数计算出来。
