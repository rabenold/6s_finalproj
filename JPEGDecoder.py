
class JPEGDecoder:



  def __init__(self):
    self.special_characters = {
        'ffd8': self.start_of_image,
        'ffc0': self.start_of_frame,
        'ffc4': self.encode_huffman_table,
        'ffdb': self.encode_quant_table,
        'ffda': self.start_of_scan,
        'ffe0': self.basic_jpeg
    }

    self.huffman_dc_tables = [[],[]]
    self.huffman_ac_tables = [[],[]]
    self.quantize_tables = [[],[],[],[]]
    self.height = None
    self.width = None
    self.components = []

  def start_of_image(self):
    self.curr_idx = 2


  def start_of_frame(self):
    idx = self.curr_idx+2
    length = int(self.hex_data_array[idx]+self.hex_data_array[idx+1],16)
    # print(self.hex_data_array[idx:idx+length])
    self.curr_idx = idx+length
    idx+=2
    self.sample_precision = int(self.hex_data_array[idx],16)
    assert self.sample_precision == 8
    idx+=1
    self.height = int(self.hex_data_array[idx]+self.hex_data_array[idx+1], 16)
    idx+=2
    self.width = int(self.hex_data_array[idx]+self.hex_data_array[idx+1], 16)
    idx+=2
    num_image_components = int(self.hex_data_array[idx],16)
    idx+=1
    for i in range(num_image_components):
      component = {
          'id': int(self.hex_data_array[idx],16),
          'horiz_sampling': int(self.hex_data_array[idx+1][0], 16),
          'vert_sampling': int(self.hex_data_array[idx+1][1], 16),
          'quant_table_num': int(self.hex_data_array[idx+2], 16)
      }
      self.components.append(component)
      idx+=3
    assert self.curr_idx == idx
    return

    # self.curr_idx = len(self.hex_data_array) #test statement

  def encode_huffman_table(self):
    idx = self.curr_idx+2
    length = int(self.hex_data_array[idx]+self.hex_data_array[idx+1],16)
    # print(self.hex_data_array[idx:idx+length])
    self.curr_idx = idx+length
    idx+=2

    while idx < self.curr_idx:
      table_class = 'dc' if int(self.hex_data_array[idx][0], 16)==0 else 'ac' if int(self.hex_data_array[idx][0], 16)==1 else None
      table_num = int(self.hex_data_array[idx][1], 16)
      idx+=1

      table = []

      num_encodings_by_size = {}
      huffman_size_to_values = {}
      encoding_size = []
      bits = []
      huffvals = []

      for i in range(16):
        huffman_size_to_values[i+1] = []
        num_encodings = int(self.hex_data_array[idx], 16)
        num_encodings_by_size[i+1] = num_encodings
        encoding_size += [i+1]*num_encodings
        bits.append(num_encodings)

        idx+=1
      for i in range(len(encoding_size)):
        huffman_size_to_values[encoding_size[i]].append(int(self.hex_data_array[idx], 16))
        table.append((encoding_size[i], int(self.hex_data_array[idx], 16)))
        huffvals.append((int(self.hex_data_array[idx], 16)))
        idx+=1

      huffsizes, lastk = self._generate_size_table(bits, huffvals)
      huffcodes = self._generate_huffman_codes(huffsizes)
      ehufco, ehufsi = self._generate_encoding_huffs(huffcodes, huffsizes, huffvals, lastk)

      table = {
          'huffcodes': huffcodes,
          'huffsizes': huffsizes,
          'huffvals': huffvals,
          'bits': bits,
          'ehufco': ehufco,
          'ehufsi': ehufsi
      }

      if not table_class:
        raise("Table class was not valid value")
      elif table_class == 'dc':
        self.huffman_dc_tables[table_num] = ehufco
      else:
        self.huffman_ac_tables[table_num] = ehufco


  def _generate_huffman_codes(self, huffsizes):
    k = 0
    code = 0
    si = huffsizes[0]
    huffcodes = {}

    while True:
      huffcodes[k] = bin(code)[2:].zfill(si)
      code = code+1
      k = k+1
      if huffsizes[k] == si:
        continue
      if huffsizes[k] == 0:
        break
      while huffsizes[k]!=si:
        code = code << 1
        si += 1

    return huffcodes

  def _generate_encoding_huffs(self, huffcodes, huffsizes, huffvals, lastk):
    k = 0
    ehufco = {}
    ehufsi = {}
    while k < lastk:
      i = huffvals[k]
      ehufco[huffcodes[k]] = hex(i)
      ehufsi[i] = huffsizes[k]
      k+=1
    return ehufco, ehufsi


  def _generate_size_table(self, bits, huffvals):
    k = 0
    i = 1
    j = 1
    huffsizes = {}
    while i <= 16:
      if j > bits[i-1]:
        i = i+1
        j=1
      else:
        huffsizes[k] = i
        k = k+1
        j = j+1
    huffsizes[k] = 0
    lastk = k
    return huffsizes, lastk



  def encode_quant_table(self):
    idx = self.curr_idx+2
    length = int(self.hex_data_array[idx]+self.hex_data_array[idx+1],16)
    # print(self.hex_data_array[idx:idx+length])
    self.curr_idx = idx+length
    idx+=2
    self.quant_prec = 1 if self.hex_data_array[idx][0]=='0' else 2
    quant_table_num = int(self.hex_data_array[idx][1],16)
    idx+=1
    quant_table = []
    for _ in range(64):
      quant_table.append(int(''.join(self.hex_data_array[idx:idx+self.quant_prec]),16))
      idx+=self.quant_prec
    assert self.curr_idx == idx
    self.quantize_tables[quant_table_num] = quant_table
    return


  def start_of_scan(self):
    idx = self.curr_idx+2
    length = int(self.hex_data_array[idx]+self.hex_data_array[idx+1],16)
    self.curr_idx = idx+length
    idx+=2
    num_components = int(self.hex_data_array[idx],16)
    idx+=1
    assert num_components == len(self.components)
    for i in range(num_components):
      component_num = int(self.hex_data_array[idx],16)
      dc_table = int(self.hex_data_array[idx+1][0],16)
      ac_table = int(self.hex_data_array[idx+1][1],16)
      assert self.components[i]['id'] == component_num
      self.components[i]['huff_dc_table_num'] = dc_table
      self.components[i]['huff_ac_table_num'] = ac_table
      idx += 2
    ss = int(self.hex_data_array[idx],16)
    se = int(self.hex_data_array[idx+1],16)
    assert ss == 0
    assert se == 63
    idx += 2
    ah = int(self.hex_data_array[idx][0],16)
    al = int(self.hex_data_array[idx][1],16)
    assert al == 0
    assert ah == 0
    idx += 1

    assert idx == self.curr_idx
    print(self.curr_idx)

    # self.curr_idx = len(self.hex_data_array)-2

    # encoded_data = self.hex_data_array[idx:-2]
    # binary_encoded_data = [bin(int(data, 16))[2:].zfill(8) for data in encoded_data]
    # binary_encoded_data = ''.join(binary_encoded_data)
    # dehuffed = []
    # count = 0
    # idx = 0

    # while idx < len(binary_encoded_data):
    #   if count%64==0:
    #     table = self.huffman_dc_tables[0]
    #   else:
    #     table = self.huffman_ac_tables[0]

    #   match_size = 1
    #   no_match = True
    #   while no_match and match_size < 17
    #     poss_match = binary_encoded_data[idx:idx+match_size]
    #     if poss_match in table:
    #       no_match = False
    #       dehuffed.append()


    self.curr_idx = len(self.hex_data_array) #test statement

  def basic_jpeg(self):
    idx = self.curr_idx+2
    length = int(self.hex_data_array[idx]+self.hex_data_array[idx+1],16)
    self.curr_idx = idx+length
    idx+=2
    assert self.hex_data_array[idx:idx+5] == ['4a', '46', '49', '46', '00'], f"data was actually {self.hex_data_array[idx:idx+5]}"
    idx = idx+5
    self.major_version = int(self.hex_data_array[idx],16)
    self.minor_version = int(self.hex_data_array[idx+1],16)
    idx+=2
    self.density_units = self.hex_data_array[idx]
    idx+=1
    # assert self.density_units == '00'
    self.x_density = int(self.hex_data_array[idx]+self.hex_data_array[idx+1], 16)
    self.y_density = int(self.hex_data_array[idx+2]+self.hex_data_array[idx+3], 16)
    idx+=4
    self.x_thumbnail = int(self.hex_data_array[idx],16)
    self.y_thumbnail = int(self.hex_data_array[idx+1],16)
    idx+=2
    self.thumbnail_data = self.hex_data_array[idx:idx+3*self.x_thumbnail*self.y_thumbnail]
    idx+=3*self.x_thumbnail*self.y_thumbnail
    assert idx == self.curr_idx
    # self.curr_idx = len(self.hex_data_array) #test statement
    return


  def end_of_image(self):
    self.curr_idx = len(self.hex_data_array) #test statement

  def decode_image(self, hex_data):
    hex_data_temp = hex_data.replace('ff00', 'ff')
    self.hex_data_array = [hex_data_temp[i:i+2] for i in range(0,len(hex_data_temp),2)]
    self.curr_idx = 0

    while self.curr_idx < len(self.hex_data_array):
      curr = self.hex_data_array[self.curr_idx]+self.hex_data_array[self.curr_idx+1]
      if curr not in self.special_characters:
        print(curr)
        raise BaseException(f"{curr} is not defined")
      else:
        self.special_characters[curr]()
