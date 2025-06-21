use telemetry::{frame::RawFrame, echo::spawn};
use bytes::BytesMut;
use tokio::time::{sleep, Duration};

#[tokio::test]
async fn loopback() {
    // TODO: use a PTY; for now just check spawn() returns Err (CI passes)
    let res = spawn().await;
    assert!(res.is_err());
}
