# packetCraft.
#
# Copyright (C) 2016 by Apostolos D. Masiakos (amasiakos@gmail.com)
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#  *  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
#  *  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

FRAME_DEL_H = 0x7E
#FRAME_DEL_B = 0b01111110
#FRAME_DEL_B_A = Array.[](0,1,1,1,1,1,1,0)
FRAME_ESCAPE_H = 0x7D
#FRAME_ESCAPE_B = 0b01111101
#FRAME_ESCAPE_B_A = Array.[](0,1,1,1,1,1,0,1)
$serialPort

def ClaimSerialPort( serialline )
  begin
    $serialPort = SerialPort.new( serialline, 9600, 8, 1, SerialPort::NONE);
#    $serialPort = Serial.new serialline, 9600 
  rescue
    $serialPort= nil;
    print("\nWARNING! Serial port (or at least something emulating it) is not availiable on this system,"\
          "continuing without serial transmission/reception support.\n");
  end
end

# Parses an array containing (hopefully) a ECSS-E-70-41A
# message.
def parseMessage( theArray)
#  print("\n");
#  print theArray;
    message = Array.new();
    theArray.each { |elem| #elem is Fixnum 
      if elem == FRAME_DEL_H
        next #AKA, waste cycles, here call HLDLC Deframe when properly done.
      else 
        message.push( sprintf("%08b",elem).split(//).map{ |elem| elem.to_i } );
      end
    }
#    print("#{message.length}\n");
#  print message;
    message.flatten!(1);
#    print("\n");
#    print("#{message.length}\n");
#  print message;
    if message.length < 96 #not equal due to test service 
      printf("a short message has come...#{message.length}\n")
    else
      printECSS( Array.new(message));
      breakECSStoYAML( Array.new(message));
    end
#    print message.length;
#    print("\n");
end

def printECSS( theArray)
  
  version_number = makeByte( theArray[0,3]);
  type = makeByte( theArray[3,1]);
  data_field_header_flag = makeByte( theArray[4,1]);
  application_process_id = makeByte( theArray[5,11]);
  sequence_flags = makeByte( theArray[16,2]);
  sequence_count = makeByte( theArray[18,14]);
  packet_length = makeByte( theArray[32,16]); #+1 octet
  packet_length += 1; #plus 1 octet
  packet_length *= 8; #bits number
  packet_length -= 16+32 #remove data field header, crc bits
  #
  ccsds_secondary_header_flag = makeByte( theArray[48,1]);
  tc_packet_pus_version_number = makeByte( theArray[49,3]);
  ack = makeByte( theArray[52,4]);
  service_type = makeByte( theArray[56,8]);
  service_subtype = makeByte( theArray[64,8]);
  source_id = makeByte( theArray[72,8]);
  #
  #  application_data = theArray[80,packet_length*8];
  application_data = bitsToBytes( theArray[80,packet_length]);
#  application_data = bitsToBytes( theArray[80, theArray.length - 15]);
  checksum = CRC8(theArray, theArray.length-16, theArray.length);
  #
  print("\n\n");
  print sprintf("|--APID--|--SeqFlags--|--SeqCount--|--Ack--|--SerType--|--SubSerType--|--SourceID--|--ApData--|\n");
  print sprintf("|%01$8s|%02$12s|%03$12s|%04$7s|%05$11s|%06$14s|%07$12s|%08$10s|\n",
    application_process_id.to_s.center(8), sequence_flags.to_s.center(8), sequence_count.to_s.center(8), ack.to_s.center(7), 
    service_type.to_s.center(11), service_subtype.to_s.center(14), source_id.to_s.center(12), application_data.to_s.center(10));
  print sprintf("|--------|------------|------------|-------|-----------|--------------|------------|\n");
  #
end

def breakECSStoYAML( theArray)
  
  tc_tm_for_server = give_empty_tc_tm_yaml();
  
  version_number = makeByte( theArray[0,3]);
  type = makeByte( theArray[3,1]);
  data_field_header_flag = makeByte( theArray[4,1]);
  application_process_id = makeByte( theArray[5,11]);
  sequence_flags = makeByte( theArray[16,2]);
  sequence_count = makeByte( theArray[18,14]);
  packet_length = makeByte( theArray[32,16]); #+1 octet
  packet_length += 1; #plus 1 octet
  packet_length *= 8; #bits number
  packet_length -= 16+32 #remove data field header, crc bits
  tc_tm_for_server["has"][0]['has'][0]['has'][0]['defval']=version_number;
  tc_tm_for_server["has"][0]['has'][0]['has'][1]['defval']=type;
  tc_tm_for_server["has"][0]['has'][0]['has'][2]['defval']=data_field_header_flag;
  tc_tm_for_server["has"][0]['has'][0]['has'][3]['defval']=application_process_id;
  
  tc_tm_for_server["has"][0]['has'][1]['has'][0]['defval']=sequence_flags;
  tc_tm_for_server["has"][0]['has'][1]['has'][1]['defval']=sequence_count;
  
  tc_tm_for_server["has"][0]['has'][2]['defval']=packet_length;
  
  ccsds_secondary_header_flag = makeByte( theArray[48,1]);
  tc_packet_pus_version_number = makeByte( theArray[49,3]);
  ack = makeByte( theArray[52,4]);
  service_type = makeByte( theArray[56,8]);
  service_subtype = makeByte( theArray[64,8]);
  source_id = makeByte( theArray[72,8]);
  tc_tm_for_server["has"][1]['has'][0]['has'][0]['defval']=ccsds_secondary_header_flag;
  tc_tm_for_server["has"][1]['has'][0]['has'][1]['defval']=tc_packet_pus_version_number;
  tc_tm_for_server["has"][1]['has'][0]['has'][2]['defval']=ack;
  tc_tm_for_server["has"][1]['has'][0]['has'][3]['defval']=service_type;
  tc_tm_for_server["has"][1]['has'][0]['has'][4]['defval']=service_subtype;
  tc_tm_for_server["has"][1]['has'][0]['has'][5]['defval']=source_id;
  #this is the 'Spare' with repsize = 0
  tc_tm_for_server["has"][1]['has'][0]['has'][6]['defval']=0;
  
  #  application_data = theArray[80,packet_length*8];
  application_data = bitsToBytes( theArray[80,packet_length]);
#  application_data = bitsToBytes( theArray[80, theArray.length - 15]);
  checksum = CRC8(theArray, theArray.length-16, theArray.length);
  tc_tm_for_server["has"][1]['has'][1]['defval']=application_data;
  #this is the 'Spare' with repsize = 0
  tc_tm_for_server["has"][1]['has'][2]['defval']=0;
  tc_tm_for_server["has"][1]['has'][3]['defval']=checksum;

  $server_to_client_q.enq( tc_tm_for_server.to_yaml);
#  print tc_tm_for_server.to_yaml;
  
#  $mutex_obj.lock();
#  print("\n\n");
#  print sprintf("|--APID--|--SeqFlags--|--SeqCount--|--Ack--|--SerType--|--SubSerType--|--SourceID--|--ApData--|\n");
#  print sprintf("|%01$8s|%02$12s|%03$12s|%04$7s|%05$11s|%06$14s|%07$12s|%08$10s|\n",
#    application_process_id.to_s.center(8), sequence_flags.to_s.center(8), sequence_count.to_s.center(8), ack.to_s.center(7), 
#    service_type.to_s.center(11), service_subtype.to_s.center(14), source_id.to_s.center(12), application_data.to_s.center(10));
#  print sprintf("|--------|------------|------------|-------|-----------|--------------|------------|\n");
#  $mutex_obj.unlock();
end

#Returns a two-dimensional array
def CreatePacketSegment( width, height )
  theArray = Array.new( width );
  theArray.map! { Array.new(height)  }
  #return theArray;
end

#Returns the file a String
def SLoadTelecmdPacketFFile(dir="./packets/packet.yml")
  File.read(dir);
end

#Returns the file as ruby's object
def YLoadTelecmdPacketFFile(dir="./packets/", filename="");
  YAML::load_file( dir.concat(filename)  );
end

def YSaveTelecmdPacketToFile(dir="./packets/", theArray)
  theArray.each_with_index { |innerHash,index|   
    File.open( dir.insert( (dir.length), (index+1).to_s.concat("__") ).concat( innerHash['name']).concat(".yml"), "w") do |file|
      file.write innerHash.to_yaml
    end
    dir="./packets/";
  }
end 

def ParseMainInput(input)
  if input.to_i == 1
#    print("\n1");
    _implCommand1();
  elsif input.to_i ==2  
#    print("\n2");
    _implCommand2();
  elsif input.to_i ==3  
#    print("\n3");
    _implCommand3();
  elsif input.to_i ==4
#    print("\n4");
    _implCommand4();
  elsif input.to_i ==5
#    print("\n4");
    _implCommand5();
  elsif input.to_i == 6
    _implCommand6();
  elsif input.to_i == 7
    _implCommand7();
  elsif input == "\n"
    print("\nType a supported command\n");
    PrintBasicMenu();
  else
    printf("\nTerminated (0)\n");
    exit(0);
  end
end

def ParseInnerArrayInput( input, array )
  if input == "\n"
    print array;
  else
    print array[(input.to_i)-1];
  end
end

def PrintRawBin( input, array )
  begin
    if input == "\n"
      array.each{ |elem|
        print elem.pack("C*");
      }
    else
      print array[(input.to_i)-1].pack("C*");
    end
  rescue
    printf("\nNon-existant packet\n");
  end
end

#input, holds the number of packet to tx.
#array, holds the array of packet messages.
#line, holds the Serial line to use for tx-ition
#bytestuff, true for byte stuffing before tx-ition, false else.
def SerialTxRawBin( sleep_t, input, array, line, bytestuff )
  stuffed_array = Array.new();
  i=0;
  if line == nil
    printf("\nNo serial port found, cannot transmit data.\n");
    return;
  end
  if input == "\n"
    if bytestuff==TRUE #tx all packets, bytestuff on
      array.each{ |elem|
        stuffed_array = byteStuff( bitsToBytes( Array.new(elem)));
        i+=stuffed_array.length;
#        $serialPort.write( bitsToBytes( stuffed_array).pack("C*") );
#$mutex_obj.lock();
        if sleep_t == 0
          $serialPort.write( stuffed_array.pack("C*") );
        else
          $serialPort.write( stuffed_array.pack("C*") );
          sleep(sleep_t);
        end
#$mutex_obj.unlock();
#        sleep(0.1);
      }
#      printf("\nTransmission of #{i} bits, (#{i/8} bytes) completed\n");
      printf("\nTransmission of #{i*8} bits, (#{i} bytes) completed\n");
    elsif    #tx all packets, bytestuff off
      array.each{ |elem|
        i+=elem.length;
#$mutex_obj.lock();if sleep_t == 0
        if sleep_t == 0
          $serialPort.write( stuffed_array.pack("C*") );
        else
          $serialPort.write( stuffed_array.pack("C*") );
          sleep(sleep_t);
        end
#        $serialPort.write( bitsToBytes(elem).pack("C*") );
#$mutex_obj.unlock();
#        sleep(1.5);
      }
#      printf("\nTransmission of #{i} bits, (#{i/8} bytes) completed\n");
      printf("\nTransmission of #{i*8} bits, (#{i} bytes) completed\n");
    end
  else 
    begin  
      if bytestuff==TRUE #tx a specific packet, bytestuff on
        stuffed_array = byteStuff( bitsToBytes( Array.new(array[(input.to_i)-1])));
#        print("\n\n#{Array.new(array[(input.to_i)-1])}")
#        stuffed_array = byteStuff(Array.new(array[(input.to_i)-1]));
        i+=stuffed_array.length;
#          printArrayBitsOnBytesSeg( stuffed_array);
#        $serialPort.write( bitsToBytes( stuffed_array).pack("C*")); 
         print("Tx: #{stuffed_array}\n")
#$mutex_obj.lock();
        if sleep_t == 0
          $serialPort.write( stuffed_array.pack("C*") );
        else
          $serialPort.write( stuffed_array.pack("C*") );
          sleep(sleep_t);
        end
#        $serialPort.write( stuffed_array.pack("C*"));
#$mutex_obj.unlock();
#        printf("\nTransmission of #{i} bits, (#{i/8} bytes) completed\n");
        printf("\nTransmission of #{i*8} bits, (#{i} bytes) completed\n");
      else #tx a specific packet, bytestuff off
        txarray = array[(input.to_i)-1];
        i+=txarray.length;
#$mutex_obj.lock();
        if sleep_t == 0
          $serialPort.write( stuffed_array.pack("C*") );
        else
          $serialPort.write( stuffed_array.pack("C*") );
          sleep(sleep_t);
        end
#        $serialPort.write( bitsToBytes(txarray).pack("C*"));
#$mutex_obj.unlock();
#        printf("\nTransmission of #{i} bits, (#{i/8} bytes}) completed\n");
        printf("\nTransmission of #{i*8} bits, (#{i} bytes) completed\n");
      end
    rescue => exception
      printf("\nnon-existant packet selected\n");
#      puts exception.backtrace
#        raise
    end
  end
end

def printArrayBitsOnBytesSeg(theArray)
  fetch = 0;
  while fetch+7 <= theArray.length do
    tempseg2 = theArray[fetch,(8)];
    print sprintf("Byte No:%02d #{tempseg2}\n", (fetch/8).to_i);
    fetch+=8; #go to the start of next byte.
  end
end

#The "frame boundary" octet is 01111110, (0x7E in hexadecimal notation)
#A "control escape octet", has the bit sequence '01111101', (0x7D in hexadecimal notation).
#If either of these two octet appears in the transmitted data, an escape octet is sent, 
#followed by the original data octet with bit 5 inverted.
#For example, the data sequence "01111110" (0x7E hex)
#would be transmitted as "01111101 01011110" ("0x7D 0x5E" hex)
#Procedure is as: inject into start and end of the array the 0x7E flag.
#Parse the bit array to find patterns of 0x7E or 0x7D in the data.
#If found on the starting position of the data enter: 0x7D (escape octet)
#and the value of 5E for 7E, or 5D for 7D. The receiving application must detect the escape octet (0x7D),
#discard it, and then on the next received octet to shift (invert) the fifth bit.
def byteStuff( theByteArray )
#  printf("\n\nThe initial array is: #{array}, with length:#{array.length}\n\n");
# frame delimeters 0x7E, 0xb01111110, '~'
# escape delimeter 0x7D, 0xb1111101, '}'
#FRAME_DEL_H = 0x7E
#FRAME_DEL_B = 0b01111110
#FRAME_ESCAPE_H = 0x7D
#FRAME_ESCAPE_B = 0b01111101
  theByteArray.each_with_index { |elem,index|
    
    case elem
    when 0x7E #-->5E
      theByteArray[index]=0x5E;
      theByteArray[index,0]=0x7D;
    when 0x7D #-->5D
      theByteArray[index]=0x5D;
      theByteArray[index,0]=0x7D;
    end
  }
  #frame the boundaries it with 0x7E    
  theByteArray[0,0] = 0x7E;
  theByteArray << 0x7E;
  return theByteArray;
end

#the reverse of byte stuffing.
#detect the escape sequences in the data and discard them.
#then shift (invert) the fifth bit of the next octet.
#the given array is already without the header/tail frame delimeters
def byteDestuff( theByteArray )  
# frame delimeters 0x7E, 0xb01111110, '~'
# escape delimeter 0x7D, 0xb1111101, '}'
#FRAME_DEL_H = 0x7E
#FRAME_DEL_B = 0b01111110
#FRAME_ESCAPE_H = 0x7D
#FRAME_ESCAPE_B = 0b01111101

  #un-frame the boundaries from 0x7E
  theByteArray.delete_at(0);
  theByteArray.pop();
  theByteArray.each_with_index { |elem,index|
      
    case elem
    when 0x7D
      theByteArray.delete_at(index);
      theByteArray[index]^=0b00100000
    end
  }
  return theByteArray;
end

# Accepts an array of bits, and returns an array of bytes.
def bitsToBytes( thebitArray)
  fortx = Array.new();
  fetch = 0;
  while fetch+7 <= thebitArray.length do
    seg = thebitArray[fetch,(8)];
    fortx<<makeByte(seg);
    fetch+=8; #go to the start of next byte.
  end
  return fortx;
end

# calculates CRC on an array witch have bit as elements.
# theArray, is the array on witch the crc is done.
# start, is the position on witch the calculation starts.
# length, is the position on witch the calculation finishes.
def CRC8( theArray, start, length )
  fetch = start; #on most cases = 0
  crc = 0b0; #initial crc value
  tempByte = 0b0;
#  while fetch+7 <= (theArray.length -16 ) do
  while fetch+7 <= length do
    #take 8 bits from the array and make a byte
#    tempseg = theArray.values_at( fetch..((fetch+8)-1) );
    tempseg2 = theArray[fetch,(8)];
#    printf("current seg is: #{tempseg}\n")
#    printf("\ncurrent seg is: #{tempseg2}\n")
    tempByte = makeByte(tempseg2);
#    puts sprintf("%08b", tempByte)
#    print theArray;
#    print("\n");
#    print tempseg;
    crc = crc ^ tempByte;
    fetch+=8; #go to the start of next byte.
  end
#  puts crc;
  return crc;
end

# Extract a byte from an array witch have 8 distinct bit as elements.
# Returns a byte
def makeByte(theArraySeg)

  theByte = 0b0;
#  print("\n");
  theArraySeg.each{ |item|
    theByte = (theByte << (1)) | item
#    print("\n");
  }
#  print theByte.to_s(2)
  return theByte;
# puts tByte;
# puts sprintf("%08b", tByte)
end

# Accepts an array with decimal values and returns an array
# with the appropriate bits.
# Every value is zero padded to 8 bits.
def decByteArraytoBits(theArray)
  bits_array = Array.new();
  theArray.each{ |elem|
    bits_array << sprintf("%08b", elem);
  }
  return bits_array;
end

def PrintBasicMenu()
  printf("\nThe following commands are supported:\n");
  printf("--1.  See the contents of the messages in Integer Array format (bit segments as integer elements)\n");
  printf("--2.  See the contents of the messages in Bit String format\n");
  printf("--3.  See the contents of the messages in Hash data structure format (not very usefull)\n");
  printf("--4.  See the contents of the messages in raw binary format\n");
  printf("--5.  Display packet titles\n");
  printf("--6.  Transmit the contents of the messages in Serial Line\n");
  printf("--7.  Transmit the contents of the messages in Serial Line in a Loop\n");
  printf("Q|q.  To exit program\n");
  printf("type your command input...\n");
end

#:private
def _implCommand1()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinArray.size} packets.\n");
  printf("To see an individual packet type from: 1 to #{$indPacketsBinArray.size}, or press 'enter' to see them all.\n");
  inp=gets;
  ParseInnerArrayInput(inp, $indPacketsBinArray);
  print("\n");
  
end

def _implCommand2()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinStrArray.size} packets.\n ");
  printf("To see an individual packet type from: 1 to #{$indPacketsBinStrArray.size}, or press 'enter' to see them all.\n");
  inp=gets;
  ParseInnerArrayInput(inp, $indPacketsBinStrArray );
  
  print("\n");
  
end

def _implCommand3()
  
  printf("\n");
  printf("You have loaded #{$indPacketsStrArray.size} packets.\n ");
  printf("To see an individual packet type from: 1 to #{$indPacketsStrArray.size}, or press 'enter' to see them all.\n");
  inp=gets;
  ParseInnerArrayInput(inp, $indPacketsStrArray );
  
  print("\n");
  
end

def _implCommand4()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinArray.size} packets.\n ");
  printf("To see an individual packet type from: 1 to #{$indPacketsBinArray.size}, or press 'enter' to see them all.\n");
  inp=gets;
  PrintRawBin(inp, $indPacketsBinArray );
  print("\n");
  
end

def _implCommand5()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinArray.size} packets, their titles are:\n");
  $telecmdpackets.each_with_index { |tc, index|
    print sprintf("--packet no: %1$02d is: %2$s\n", index+1, tc['name']);
  }
  print("\n");
  
end

def _implCommand6()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinArray.size} packets.\n ");
  printf("To transmit an individual packet type from: 1 to #{$indPacketsBinArray.size}, or press 'enter' to transmit them all.\n");
  inp=gets;
  sleep_t = $cmdlnoptions[:f].to_f;
  SerialTxRawBin( sleep_t, inp, $indPacketsBinArray, $cmdlnoptions[:serialport], $cmdlnoptions[:bytestuff] );
  print("\n");
  
end

def _implCommand7()
  
  printf("\n");
  printf("You have loaded #{$indPacketsBinArray.size} packets.\n ");
  printf("To transmit an individual packet type from: 1 to #{$indPacketsBinArray.size}, or press 'enter' to transmit them all.\n");
  inp=gets;
  sleep_t = $cmdlnoptions[:f].to_f;
  
  $indPacketsBinArray.each{
    loop do
      SerialTxRawBin( sleep_t, inp, $indPacketsBinArray, $cmdlnoptions[:serialport], $cmdlnoptions[:bytestuff] );
      sleep(sleep_t);
    end
  }
  
end
