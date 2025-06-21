use bytes::{Buf, BufMut, BytesMut};
use crc::{Crc, Algorithm};

const SYNC: u16 = 0x55AA;

/// CCITT-FALSE: width=16, poly=0x1021, init=0xFFFF, refin=false, refout=false, xorout=0x0000
const CRC_CCITT_FALSE: Algorithm<u16> = Algorithm {
    width:   16,
    poly:    0x1021,
    init:    0xFFFF,
    refin:   false,
    refout:  false,
    xorout:  0x0000,
    check:   0x29B1,
    residue: 0x0000,
};

const CRC: Crc<u16> = Crc::<u16>::new(&CRC_CCITT_FALSE);

/// Raw wire-level frame (payload already protobuf-encoded)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RawFrame {
    pub payload: Vec<u8>,
}

impl RawFrame {
    pub fn to_bytes(&self, out: &mut BytesMut) {
        out.put_u16(SYNC);
        out.put_u16(self.payload.len() as u16);
        out.extend_from_slice(&self.payload);
        out.put_u16(CRC.checksum(&self.payload));
    }

    /// Extract one valid frame if enough bytes are present.
    pub fn parse(buf: &mut BytesMut) -> Option<Self> {
        loop {
            if buf.len() < 4 {
                return None;
            }

            // resync until we see SYNC
            if buf[..2] != SYNC.to_be_bytes() {
                buf.advance(1);
                continue;
            }

            let len = u16::from_be_bytes([buf[2], buf[3]]) as usize;
            if buf.len() < len + 6 {
                return None; // incomplete
            }

            buf.advance(4);                       // drop SYNC+LEN
            let payload = buf.split_to(len).to_vec();
            let crc_read = u16::from_be_bytes([buf[0], buf[1]]);
            buf.advance(2);                       // drop CRC bytes

            if CRC.checksum(&payload) == crc_read {
                return Some(RawFrame { payload });
            }
            // bad CRC ⇒ drop first byte after sync and rescan
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip() {
        let p = b"hi".to_vec();
        let mut buf = BytesMut::new();
        RawFrame { payload: p.clone() }.to_bytes(&mut buf);
        let mut buf2 = buf.clone();
        assert_eq!(RawFrame::parse(&mut buf2).unwrap().payload, p);
        assert!(buf2.is_empty());
    }
}
