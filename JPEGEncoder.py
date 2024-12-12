luminance_quantization = [  [16,  11,  10,  16,  24,  40,  51,  61],
  [12,  12,  14,  19,  26,  58,  60,  55],
  [14,  13,  16,  24,  40,  57,  69,  56],
  [14,  17,  22,  29,  51,  87,  80,  62],
  [18,  22,  37,  56,  68, 109, 103,  77],
  [24,  35,  55,  64,  81, 104, 113,  92],
  [49,  64,  78,  87, 103, 121, 120, 101],
  [72,  92,  95,  98, 112, 100, 103,  99]]

zigzag = [
    [0,1,5,6,14,15,27,28],
    [2,4,7,13,16,26,29,42],
    [3,8,12,17,25,30,41,43],
    [9,11,18,24,31,40,44,53],
    [10,19,23,32,39,45,52,54],
    [20,22,33,38,46,51,55,60],
    [21,34,37,47,50,56,59,61],
    [35,36,48,49,57,58,62,63]
]

luminance_component = {'id': 1, 'horiz_sampling': 1, 'vert_sampling': 1, 'quant_table_num': 0}

class JPEGEncoder:

  # self.special_characters = {
  #       'ffd8': self.start_of_image,
  #       'ffc0': self.start_of_frame,
  #       'ffc4': self.encode_huffman_table,
  #       'ffdb': self.encode_quant_table,
  #       'ffda': self.start_of_scan,
  #       'ffe0': self.basic_jpeg
  #   }

  def encode_quantization_table(self, table, table_index=0):
    frame_hex = 'ffdb00430'
    frame_hex += str(table_index)
    table_hex = "ff"*64
    for u in range(8):
      for v in range(8):
        idx = zigzag[u][v]
        quant = hex(table[u][v])[2:].zfill(2)
        table_hex = table_hex[0:2*idx] + quant + table_hex[2*idx+2:]
    return frame_hex + table_hex

  def basic_jpeg(self, major_version=1, minor_version=1, x_density=1, y_density=1, thumbnail_x=0, thumbnail_y=0, thumbnail=[]):
    frame_code = 'ffe0'
    frame_hex = '4a46494600'
    frame_hex += hex(major_version)[2:].zfill(2)
    frame_hex += hex(minor_version)[2:].zfill(2)
    frame_hex += '00'+hex(x_density)[2:].zfill(4)+hex(y_density)[2:].zfill(4)
    frame_hex += hex(thumbnail_x)[2:].zfill(2)
    frame_hex += hex(thumbnail_y)[2:].zfill(2)
    thumbnail_hex = [hex(data)[2:].zfill(2) for data in thumbnail]
    frame_hex += ''.join(thumbnail_hex)
    return frame_code + hex(2+len(frame_hex)//2)[2:].zfill(4) + frame_hex


  def encode_start_of_frame(self, components, height=180, width=320):
    frame_code = 'ffc0'
    frame_hex = '08'
    frame_hex += hex(height)[2:].zfill(4)
    frame_hex += hex(width)[2:].zfill(4)
    frame_hex += hex(len(components))[2:].zfill(2)
    for component in components:
      frame_hex += hex(component['id'])[2:].zfill(2)
      frame_hex += hex(component['horiz_sampling'])[2:].zfill(1)
      frame_hex += hex(component['vert_sampling'])[2:].zfill(1)
      frame_hex += hex(component['quant_table_num'])[2:].zfill(2)
    return frame_code + hex(2+len(frame_hex)//2)[2:].zfill(4) + frame_hex

  def encode_image_data(self, data, save_path='test.jpg'):
    image_hex = 'ffd8'
    image_hex += self.basic_jpeg()
    image_hex += self.encode_quantization_table(luminance_quantization)
    image_hex += self.encode_start_of_frame([luminance_component])

