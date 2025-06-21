//! Echo USB dongle driver (auto-detect + async read/write)

use anyhow::{Context, Result};
use bytes::BytesMut;
use std::sync::Arc;
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    sync::{broadcast, Mutex},
    task,
};
use tokio_serial::{SerialPortBuilderExt, SerialPortType, SerialStream};

use crate::frame::RawFrame;

const VID: u16 = 0x1209;   // TODO: replace with real VID
const PID: u16 = 0xE001;   // TODO: replace with real PID

fn find_echo_port() -> Result<String> {
    for port in tokio_serial::available_ports()? {
        if let SerialPortType::UsbPort(usb) = &port.port_type {
            if usb.vid == VID && usb.pid == PID {
                return Ok(port.port_name);
            }
        }
    }
    anyhow::bail!("Echo dongle not found");
}

/// Spawns RX and TX tasks; returns a broadcast sender you can clone.
///
/// * TX: call `sender.send(payload)` to write
/// * RX: subscribe via `sender.subscribe()` to receive payloads
pub async fn spawn() -> Result<broadcast::Sender<Vec<u8>>> {
    let port_name = find_echo_port()?;
    let stream: SerialStream = tokio_serial::new(port_name, 921_600)
        .open_native_async()
        .context("opening serial")?;

    let port = Arc::new(Mutex::new(stream));
    let (tx_out, mut rx_in) = broadcast::channel::<Vec<u8>>(128);
    let tx_clone = tx_out.clone();

    // ── RX task ──────────────────────────────────────────────────────────────
    {
        let port = Arc::clone(&port);
        let tx = tx_out;
        task::spawn(async move {
            let mut buf = BytesMut::with_capacity(4096);
            loop {
                let mut tmp = [0u8; 512];
                let n = port.lock().await.read(&mut tmp).await?;
                buf.extend_from_slice(&tmp[..n]);
                while let Some(frame) = RawFrame::parse(&mut buf) {
                    let _ = tx.send(frame.payload);
                }
            }
            #[allow(unreachable_code)]
            Ok::<_, anyhow::Error>(())
        });
    }

    // ── TX task ──────────────────────────────────────────────────────────────
    {
        let port = Arc::clone(&port);
        task::spawn(async move {
            while let Ok(payload) = rx_in.recv().await {
                let mut out = BytesMut::with_capacity(payload.len() + 6);
                RawFrame { payload }.to_bytes(&mut out);
                port.lock().await.write_all(&out).await?;
            }
            #[allow(unreachable_code)]
            Ok::<_, anyhow::Error>(())
        });
    }

    Ok(tx_clone)
}
