-- Copyright 2024 Lennart Augustsson
-- See LICENSE file for full license.
module System.IO.Serialize(
  hSerialize, hDeserialize,
  writeSerialized, writeSerializedCompressed,
  readSerialized,
  ) where
import Prelude(); import MiniPrelude
import Primitives(Ptr)
import System.IO_Handle
import System.IO

primHSerialize   :: forall a . Ptr BFILE -> a -> IO ()
primHSerialize    = primitive "IO.serialize"
primHDeserialize :: forall a . Ptr BFILE -> IO a
primHDeserialize  = primitive "IO.deserialize"

hSerialize   :: forall a . Handle -> a -> IO ()
hSerialize h a = withHandle h $ \ p -> primHSerialize p a

hDeserialize :: forall a . Handle -> IO a
hDeserialize h = withHandle h primHDeserialize

writeSerialized :: forall a . FilePath -> a -> IO ()
writeSerialized p s = do
  h <- openBinaryFile p WriteMode
  hSerialize h s
  hClose h

foreign import ccall "add_lz77_compressor" c_add_lz77_compressor :: Ptr BFILE -> IO (Ptr BFILE)
foreign import ccall "add_lz77_decompressor" c_add_lz77_decompressor :: Ptr BFILE -> IO (Ptr BFILE)

writeSerializedCompressed :: forall a . FilePath -> a -> IO ()
writeSerializedCompressed p s = do
  h <- openBinaryFile p WriteMode
  withHandle h $ \ p -> do
    hPutChar h 'z'                               -- indicate compressed
    h' <- mkHandle =<< c_add_lz77_compressor p
    hSerialize h' s
    hClose h'

-- Read compressed or uncompressed
readSerialized :: forall a . FilePath -> IO a
readSerialized p = do
  h <- openBinaryFile p ReadMode
  withHandle h $ \ p -> do
    c <- hLookAhead h
    h' <- if c == 'z' then do                    -- compressed?
            hGetChar h   -- get rid of the 'z'
            mkHandle =<< c_add_lz77_decompressor p
          else
            return h
    a <- hDeserialize h'
    hClose h'
    return a
