//! JsMessage —— Dart↔JS 通信通道的消息类型。

use crate::api::js_value::JsValue;

/// Dart↔JS 双向通信通道中的一条消息。
///
/// - `event`: 事件名称/类型标识，如 `"log"`、`"data"`、`"error"`
/// - `data`: 结构化的负载数据，使用 [JsValue] 表示
pub struct JsMessage {
    pub event: String,
    pub data: JsValue,
}
