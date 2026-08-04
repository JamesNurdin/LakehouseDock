WITH
  -- Sample a fraction of call_center rows
  cc_samp AS (
    SELECT *
    FROM call_center
    TABLESAMPLE BERNOULLI (10)
  ),
  -- Raw source tables (no filters, just to give them short aliases)
  cs AS (
    SELECT * FROM catalog_sales
  ),
  ws AS (
    SELECT * FROM web_sales
  ),
  wr AS (
    SELECT * FROM web_returns
  ),
  td AS (
    SELECT * FROM time_dim
  ),
  wp AS (
    SELECT * FROM web_page
  ),
  -- First aggregated branch – uses a FULL OUTER JOIN and a HAVING clause
  agg_a AS (
    SELECT
      cc.cc_name,
      td.t_hour,
      SUM(cs.cs_net_paid_inc_ship_tax) AS metric,
      COUNT(DISTINCT cs.cs_order_number) AS cnt
    FROM cs
    FULL OUTER JOIN td ON cs.cs_sold_time_sk = td.t_time_sk               -- join #1 (FULL OUTER)
    JOIN cc_samp cc ON cs.cs_call_center_sk = cc.cc_call_center_sk          -- join #2
    JOIN ws ON cs.cs_order_number = ws.ws_order_number                       -- join #3
    JOIN wp ON ws.ws_web_page_sk = wp.wp_web_page_sk                         -- join #4
    JOIN wr ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk                                 -- join #5 (two predicates, still one join clause)
    WHERE cs.cs_ext_wholesale_cost > 1000
    GROUP BY cc.cc_name, td.t_hour
    HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 20000                     -- HAVING clause
  ),
  -- Second aggregated branch – re‑uses tables under different aliases to add more joins
  agg_b AS (
    SELECT
      cc2.cc_name AS cc_name,
      td2.t_hour AS t_hour,
      SUM(cs2.cs_ext_list_price) AS metric,
      COUNT(DISTINCT cs2.cs_order_number) AS cnt
    FROM cs cs2
    JOIN cc_samp cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk        -- join #6
    JOIN td td2 ON cs2.cs_sold_time_sk = td2.t_time_sk                         -- join #7
    LEFT JOIN ws ws2 ON cs2.cs_order_number = ws2.ws_order_number            -- join #8 (LEFT)
    LEFT JOIN wp wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk                -- join #9 (LEFT)
    LEFT JOIN wr wr2 ON ws2.ws_order_number = wr2.wr_order_number
            AND ws2.ws_item_sk = wr2.wr_item_sk                                 -- join #10 (LEFT)
    WHERE cs2.cs_ext_list_price > 2000
    GROUP BY cc2.cc_name, td2.t_hour
  ),
  -- Union the two aggregated branches (UNION DISTINCT)
  combined AS (
    SELECT cc_name, t_hour, metric, cnt FROM agg_a
    UNION DISTINCT
    SELECT cc_name, t_hour, metric, cnt FROM agg_b
  ),
  -- A set derived from web_sales that will be subtracted using EXCEPT
  high_ws AS (
    SELECT
      cc.cc_name AS cc_name,
      td.t_hour AS t_hour,
      SUM(ws.ws_net_paid_inc_ship) AS metric,
      COUNT(*) AS cnt
    FROM cs
    JOIN cc_samp cc ON cs.cs_call_center_sk = cc.cc_call_center_sk    -- reuse join rule
    JOIN td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ws ON cs.cs_order_number = ws.ws_order_number
    WHERE ws.ws_net_paid_inc_ship > 5000
    GROUP BY cc.cc_name, td.t_hour
  ),
  -- Subtract the high‑web‑sales rows from the combined set (EXCEPT)
  final_set AS (
    SELECT * FROM combined
    EXCEPT
    SELECT * FROM high_ws
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY metric DESC) AS row_num,   -- global row number
  cc_name,
  t_hour,
  metric,
  cnt,
  -- scalar sub‑query example: total number of return rows with a large return amount
  (SELECT COUNT(*) FROM web_returns WHERE wr_return_amt > 1000) AS high_return_cnt
FROM final_set
ORDER BY metric DESC
LIMIT 100
