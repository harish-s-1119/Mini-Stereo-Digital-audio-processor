`timescale 1ns / 10ps

module MSDAP_TB;
  reg Sclk, Dclk;
  reg Start, Reset_n, Frame, InputL, InputR;
  wire InReady, OutReady, OutputL, OutputR;
  parameter T_Sclk = 1;
  parameter T_Dclk = 33;
  parameter M_input = 62;
  
  MSDAP uut( .Sclk(Sclk), .Dclk(Dclk), .Start(Start), .Reset_n(Reset_n), 
  .Frame(Frame), .InputL(InputL), .InputR(InputR), .InReady(InReady), 
  .OutReady(OutReady), .OutputL(OutputL), .OutputR(OutputR) );
  
  int fd,fd2,i,j;
  string line,sL,sR,line2,sL40,sR40;
  reg [15:0] inL, inR;
  reg [39:0] outL, outR, outL_golden, outR_golden;
  reg L_correct, R_correct;
  
  initial begin
    Sclk=0; Dclk=0;
    Start=0; Reset_n=1; Frame=0; InputL=0; InputR=0;
    #1  Start=1;
    #2  Start=0;

    fd = $fopen("/home/013/h/hx/hxs230028/verilog_final_submit/data1.in", "r");
    if(fd) 
        $display("Successfully read in data1.in.");
    else begin
        $display("Failed to read in data1.in.");
        $finish;
    end
    
    repeat(4) begin
        $fgets(line,fd); // Skip 4 lines at the beginning
        //$display("@[data1.in] %s",line);
    end 
    
    @(posedge InReady);
    
    repeat(16) begin
        $fgets(line,fd);
        //$display("@[data1.in] %s",line);
        $sscanf(line,"%s %s", sL, sR);
        inL = sL.atohex(); inR = sR.atohex();
        for(i=0;i<16;i=i+1) begin
            @(posedge Dclk);
            Frame = (0==i);
            InputL = inL[i]; InputR = inR[i];
        end
    end
    
    repeat(2) begin
        @(posedge Dclk);
        $fgets(line,fd); // Skip 2 lines
        //$display("@[data1.in] %s",line);
    end 
    
    repeat(512) begin
        $fgets(line,fd);
        //$display("@[data1.in] %s",line);
        $sscanf(line,"%s %s", sL, sR);
        inL = sL.atohex(); inR = sR.atohex();
        for(i=0;i<16;i=i+1) begin
            @(posedge Dclk);
            Frame = (0==i);
            InputL = inL[i]; InputR = inR[i];
        end
    end
    
    repeat(2) begin
        @(posedge Dclk);
        $fgets(line,fd); // Skip 2 lines
        //$display("@[data1.in] %s",line);
    end 
    
    repeat(M_input) begin
        $fgets(line,fd);
        //$display("@[data1.in] %s",line);
        if(line.len() > 32) begin // lines labeled with "reset" has larger length
          Reset_n = 0;
          @(posedge Sclk); @(posedge Sclk);
          Reset_n = 1;
          continue;
        end
        $sscanf(line,"%s %s", sL, sR);
        inL = sL.atohex(); inR = sR.atohex();
        for(i=0;i<16;i=i+1) begin
            @(posedge Dclk);
            Frame = (0==i);
            InputL = inL[i]; InputR = inR[i];
        end
    end
    
    $fclose(fd);
    @(posedge Dclk); @(posedge Dclk);
    $stop;
  end

  initial begin
    fd2 = $fopen("/home/013/h/hx/hxs230028/verilog_final_submit/data2.out", "r");    
    if(fd2) 
        $display("Successfully read in data2.out.");
    else begin
        $display("Failed to read in data2.out.");
        $finish;
    end
    outL<=0; outR<=0;
    repeat(6393) begin
      @(posedge OutReady);
      $fgets(line2,fd2);
      $sscanf(line2,"%s %s", sL40, sR40);
      outL_golden = sL40.atohex(); outR_golden = sR40.atohex();
      @(negedge Sclk);
      while(OutReady) begin
        outL = {OutputL,outL[39:1]};
        outR = {OutputR,outR[39:1]};
        @(negedge Sclk);
      end
      L_correct = (outL == outL_golden);
      R_correct = (outR == outR_golden);
    end
    $fclose(fd2);
  end 
  
  always begin
    #T_Sclk Sclk = ~Sclk;
  end

  always begin
    #T_Dclk Dclk = ~Dclk;
  end

  function int contains(string a, string b);
    // checks if string A contains string B
    int len_a;
    int len_b;
    len_a = a.len();
    len_b = b.len();
    // $display("a (%s) len %d -- b (%s) len %d", a, len_a, b, len_b);
    for( int i=0; i<len_a; i++) begin
        if(a.substr(i,i+len_b-1) == b)
            return 1;
    end
    return 0;
  endfunction
  
endmodule

