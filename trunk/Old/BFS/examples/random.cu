/******************************************************************************
 * Copyright 2010 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 ******************************************************************************/

#pragma once

#include <math.h>
#include <time.h>
#include <stdio.h>

#include <string>
#include <sstream>
#include <iostream>

#include <fstream>
#include <deque>
#include <algorithm>

#include <b40c_util.h>					// Misc. utils (random-number gen, I/O, etc.)
#include <test_utils.cu>


/******************************************************************************
 * Random Graph Construction Routines
 ******************************************************************************/

/**
 * Builds a random CSR graph by adding edges edges to nodes nodes by randomly choosing
 * a pair of nodes for each edge.  There are possibilities of loops and multiple 
 * edges between pairs of nodes.    
 * 
 * If src == -1, it is assigned a random node.  Otherwise it is verified 
 * to be in range of the constructed graph.
 * 
 * Returns 0 on success, 1 on failure.
 */
template<typename IndexType, typename ValueType>
int BuildRandomGraph(
	IndexType nodes,
	IndexType edges,
	IndexType &src,
	CsrGraph<IndexType, ValueType> &csr_graph,
	bool undirected)
{ 
	typedef CooEdgeTuple<IndexType, ValueType> EdgeTupleType;

	if ((nodes < 0) || (edges < 0)) {
		fprintf(stderr, "Invalid graph size: nodes=%d, edges=%d", nodes, edges);
		return -1;
	}

	time_t mark0 = time(NULL);
	printf("  Selecting %llu %s random edges in COO format... ", 
		(unsigned long long) edges, (undirected) ? "undirected" : "directed");
	fflush(stdout);

	// Construct COO graph
	IndexType directed_edges = (undirected) ? edges * 2 : edges;
	EdgeTupleType *coo = (EdgeTupleType*) malloc(sizeof(EdgeTupleType) * directed_edges);
	for (int i = 0; i < edges; i++) {
		coo[i].row = RandomNode(nodes);
		coo[i].col = RandomNode(nodes);
		coo[i].val = 1;
		if (undirected) {
			// Reverse edge
			coo[edges + i].row = coo[i].col;
			coo[edges + i].col = coo[i].row;
			coo[edges + i].val = 1;
		}
	}

	time_t mark1 = time(NULL);
	printf("Done selecting (%ds).\n", (int) (mark1 - mark0));
	fflush(stdout);
	
	// Convert sorted COO to CSR
	csr_graph.FromCoo(coo, nodes, directed_edges);
	free(coo);

	// If unspecified, assign default source.  Otherwise verify source range.
	if (src == -1) {
		// Random source
		src = RandomNode(csr_graph.nodes);
	} else if ((src < 0 ) || (src > csr_graph.nodes)) {
		fprintf(stderr, "Invalid src: %d", src);
		csr_graph.Free();
		return -1;
	}
	
	return 0;
}
