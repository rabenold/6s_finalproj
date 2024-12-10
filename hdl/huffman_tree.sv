`timescale 1ns / 1ps
`default_nettype none


//data width to 16 
module huffman_tree_builder #(parameter TABLE_SIZE = 256, parameter DATA_WIDTH = 16)(
    input logic clk,
    input logic rst_in,
    input logic valid_in,
    // input logic [DATA_WIDTH-1:0] data_in,
    input logic [DATA_WIDTH-1:0] sorted_table [TABLE_SIZE-1:0],
    input logic [DATA_WIDTH-1:0] freq_table [TABLE_SIZE-1:0],
    // output logic [DATA_WIDTH-1:0] encoded_data,
    output logic encoded_valid,
    output logic actually_done, 
    output [TABLE_SIZE-1][31:0] codes_out
    // output logic [255:0] huffman_tree   //flattened huffman tree 
);

//  logic [TABLE_SIZE-1:0][31:0] huffman_codes;

    typedef struct packed {
        logic [DATA_WIDTH-1:0] symbol;    // The symbol (data value)
        logic [31:0] frequency;           // Frequency of the symbol
        int left_child;                   // reference to the left 
        int right_child;                  //  reference to the right
    } huffman_node_t;

   // States for the state machine
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        INIT_HEAP = 3'b001,
        BUILD_TREE = 3'b010,
        HEAPIFY = 3'b011,
        EXTRACT_MIN = 3'b100,
        FINALIZE = 3'b101
    } state_t;
    state_t state, next_state;

    huffman_node_t heap[2*TABLE_SIZE-1];
    int heap_size = 0;                      // node counter 
    int tree_root;         //root, duh 
    int node_count = 0; 
    logic build_done;

    logic [DATA_WIDTH-1:0] min1_symbol, min2_symbol;
    logic [31:0] min1_frequency, min2_frequency;
    logic [DATA_WIDTH-1:0] new_symbol;
    logic [31:0] new_frequency;

    //Create nodes for each symbol in frequency table, frequency and its symbol
    //so have original sorted array, and array of frequency

    //priority queue of nodes on frequency. node with smallest freq is at root 
// Initializing the heap with the symbols and frequencies
  
    // Initialization of the heap with the symbols and frequencies
    always_ff @(posedge clk or posedge rst_in) begin
        if (rst_in) begin
            heap_size <= 0;
            node_count <= 0;
            build_done <= 0;
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end


    

    // HELPER FUNCTIONS 
    // Heapify function to ensure the heap property is maintained
    function void heapify(input int idx);
        int smallest;
        int left, right;
        
        left = 2*idx + 1;
        right = 2*idx + 2;

        smallest = idx;

        if (left < heap_size && heap[left].frequency < heap[smallest].frequency) begin
            smallest = left;
        end

        if (right < heap_size && heap[right].frequency < heap[smallest].frequency) begin
            smallest = right;
        end

        if (smallest != idx) begin
            swap(idx, smallest);
            heapify(smallest);
        end
    endfunction

    // Swap two nodes in the heap
    function void swap(input int i, input int j);
        huffman_node_t temp;
        temp = heap[i];
        heap[i] = heap[j];
        heap[j] = temp;
    endfunction


   // State machine: control the operations
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                if (valid_in) begin
                    next_state <= INIT_HEAP;  //into the init state 
                end
            end

            INIT_HEAP: begin
                // fill the heap with the initial symbols and frequencies
                //all children to -1 
                for (int i = 0; i < TABLE_SIZE; i++) begin
                    heap[i].symbol <= sorted_table[i];
                    heap[i].frequency <= freq_table[i];
                    heap[i].left_child <= -1;
                    heap[i].right_child <= -1;
                end
                heap_size <= TABLE_SIZE;
                next_state <= BUILD_TREE;
            end

            BUILD_TREE: begin
                //go extract smallest nodes, merge 
                if (heap_size > 1) begin
                    next_state <= EXTRACT_MIN;
                end else begin
                    next_state <= FINALIZE;
                end
            end

            EXTRACT_MIN: begin
                // Parallel extraction of two min nodes 
                min1_symbol <= heap[0].symbol;
                min1_frequency <= heap[0].frequency;
                min2_symbol <= heap[1].symbol;
                min2_frequency <= heap[1].frequency;
                
                // Swap and heapify operations are parallelized
                heap[0] <= heap[heap_size - 1];
                heap_size <= heap_size - 1;
                heapify(0); // Parallel heapify from index 0

                next_state <= HEAPIFY;
            end

            HEAPIFY: begin
                // Perform the heapify operation
                heapify(0);
                //then merge into a new (merged freq) node and heapify 

                // Create new internal node and insert it back to heap
                new_symbol <= 0;  // Internal node does not have a symbol
                new_frequency <= min1_frequency + min2_frequency;

                heap[heap_size].symbol <= new_symbol;
                heap[heap_size].frequency <= new_frequency;
                heap[heap_size].left_child <= node_count;
                heap[heap_size].right_child <= node_count + 1;

                node_count <= node_count + 2;
                heap_size <= heap_size + 1;

                next_state <= BUILD_TREE;
            end

            FINALIZE: begin
                //tree doth hath grown
                tree_root <= 0;
                build_done <= 1;  // Mark the build as done
                next_state <= IDLE;
            end

        endcase
    end

    //////////////////////////////
      //TRAVERSAL HAPPENS HERE// 
    //////////////////////////////
  
    logic [TABLE_SIZE-1:0][31:0] huffman_codes; // Array of Huffman codes (32 bits wide for simplicity)
    function void traverse_tree(input int node_idx, input logic [31:0] current_code, input int code_length);
            if (node_idx < 0) return;  // Null node, return

            // Check if it's a leaf node (symbol node)
            if (heap[node_idx].left_child == -1 && heap[node_idx].right_child == -1) begin
                // Leaf node found, store the current Huffman code for this symbol
                huffman_codes[heap[node_idx].symbol] = current_code;
            end else begin
                // Internal node, traverse left and right children with updated code
                traverse_tree(heap[node_idx].left_child, current_code << 1, code_length + 1);  // Append '0' for left child
                traverse_tree(heap[node_idx].right_child, current_code << 1 | 1, code_length + 1);  // Append '1' for right child
            end
    endfunction 
    logic final_flag; 

    always_ff @(posedge clk or posedge rst_in) begin
        if (rst_in) begin
            encoded_valid <= 0;
            encoded_data <= 0;
            final_flag <= 0;
            actually_done <= 0;
            huffman_counter = 0; 
        end else if (build_done && !final_flag) begin
            // Start traversing the tree from the root to generate the codes
            traverse_tree(tree_root, 0, 0); // Start from root with empty code
            //done 
            // encoded_valid <= 1;
            // encoded_data <= huffman_codes[sorted_table[0]]; // Fetch the Huffman code for the first symbol
            final_flag <= 1; 
        end
        else if (final_flag && build_done) begin
            if(huffman_counter<DATA_WIDTH)begin
                encoded_valid <= 1; 
                codes_out[huffman_counter] <= huffman_codes[huffman_counter];
                huffman_counter <= huffman_counter + 1; 
            end 
            actually_done <= 1; 
            encoded_valid <= 0; 
        end 
    end

endmodule
`default_nettype wire

