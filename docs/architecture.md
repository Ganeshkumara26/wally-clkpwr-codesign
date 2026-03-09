# Final Architecture Diagram (v017)

This diagram visualizes the final Clock-Power Codesign modifications applied to the Wally (CVW) RISC-V core.

```mermaid
graph TD
    subgraph Decode_Stage ["Decode Stage"]
        CU["Control Unit"] --> |RegWrite| ICG_RF["ICG Cell (Register File)"]
        CU --> |M-Ext Enable| ICG_M["ICG Cell (M-Extension)"]
        CU --> |ALUOp / AUIPC| Clamp_Ctrl["Isolation Controller"]
    end

    subgraph Clock_Tree ["Clock Tree Synthesis (CTS)"]
        Root_Clk["Root Clock (100MHz)"] --> CTS_Buf1["CTS Buffer Tree (Un-Gated)"]
        Root_Clk --> ICG_RF
        Root_Clk --> ICG_M
        
        CTS_Buf1 --> ALU["ALU Combinational Cloud"]
        ICG_RF --> |Gated clk_rf| RF["Integer Register File (32x32)"]
        ICG_M --> |Gated clk_mext| MEXT["M-Extension (Multiplier)"]
    end

    subgraph Execute_Stage ["Execute Stage (Operand Isolation)"]
        Clamp_Ctrl --> |isolate_n| AND_Clamp1["AND Clamp (rs1)"]
        Clamp_Ctrl --> |isolate_n| AND_Clamp2["AND Clamp (rs2)"]
        
        RF --> AND_Clamp1
        RF --> AND_Clamp2
        
        AND_Clamp1 --> ALU
        AND_Clamp2 --> ALU
        
        AND_Clamp1 --> MEXT
        AND_Clamp2 --> MEXT
    end

    classDef icg fill:#f97316,stroke:#ea580c,stroke-width:2px,color:#fff;
    classDef clamp fill:#8b5cf6,stroke:#7c3aed,stroke-width:2px,color:#fff;
    classDef block fill:#1e293b,stroke:#334155,stroke-width:1px,color:#f8fafc;

    class ICG_RF,ICG_M icg;
    class AND_Clamp1,AND_Clamp2,Clamp_Ctrl clamp;
    class RF,MEXT,ALU,CU,Root_Clk,CTS_Buf1 block;
```

## Implementation Notes
- **Orange Nodes (ICG):** Latch-based Integrated Clock Gating cells (`cvw_icg_cell.sv`) injected to shut off the clock to dense sequential blocks when they are not written to.
- **Purple Nodes (Operand Isolation):** Combinational AND-clamps that lock the data inputs to `0` when the execution units are not active, preventing power-hungry combinational toggling from propagating through the ALU and Multiplier.
