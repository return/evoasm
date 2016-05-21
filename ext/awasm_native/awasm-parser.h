#pragma once

#include "awasm-src-graph.h"

typedef struct {
  void *scanner;
} awasm_parser;

typedef struct {
  awasm_parser *parser;
  awasm_src_graph *graph;
  uint32_t col;
  uint32_t last_col;
  uint32_t line;
  uint32_t last_line;
  uint32_t pos;
  uint32_t last_pos;
} _awasm_parse_ctx;