/*
Goal: Analyze profitability and loss by item brand, return reason and store location, while counting distinct customers and summing distinct item prices. The query joins all 13 selected TPC‑DS tables, applies realistic selective filters, uses an IN‑subquery and a scalar subquery, computes multiple DISTINCT aggregates, groups the results, orders by store profit and limits the output.
*/
SELECT
  i.i_brand,
  r.r_reason_desc,
  s.s_state,
  sm.sm_type,
  COUNT(DISTINCT c.c_customer_sk)            AS distinct_customers,
  SUM(DISTINCT i.i_current_price)            AS distinct_price_sum,
  SUM(ss.ss_net_profit)                     AS total_store_profit,
  SUM(ws.ws_net_profit)                     AS total_web_profit,
  SUM(cr.cr_net_loss)                       AS total_catalog_loss,
  SUM(wr.wr_net_loss)                       AS total_web_return_loss
FROM
  item i
  JOIN store_sales ss               ON ss.ss_item_sk      = i.i_item_sk
  JOIN catalog_returns cr           ON cr.cr_item_sk      = i.i_item_sk
  JOIN web_sales ws                 ON ws.ws_item_sk      = i.i_item_sk
  JOIN web_returns wr               ON wr.wr_item_sk      = i.i_item_sk
                                      AND wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv                ON inv.inv_item_sk    = i.i_item_sk
  JOIN warehouse w                  ON inv.inv_warehouse_sk = w.w_warehouse_sk
  JOIN ship_mode sm                 ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r                     ON cr.cr_reason_sk    = r.r_reason_sk
  JOIN store s                      ON ss.ss_store_sk     = s.s_store_sk
  JOIN customer c                   ON ss.ss_customer_sk  = c.c_customer_sk
  JOIN customer_address ca          ON ss.ss_addr_sk      = ca.ca_address_sk
  JOIN web_page wp                  ON ws.ws_web_page_sk  = wp.wp_web_page_sk
WHERE
  i.i_brand = 'Brand#12'                                         -- filter 1 (realistic literal)
  AND s.s_state = 'CA'                                            -- filter 2
  AND sm.sm_type = 'AIR'                                          -- filter 3
  AND r.r_reason_desc LIKE '%damaged%'                            -- filter 4
  AND ss.ss_store_sk IN (
        SELECT s2.s_store_sk FROM store s2 WHERE s2.s_country = 'United States'
    )                                                            -- IN‑subquery filter (uncorrelated)
  AND ws.ws_net_paid_inc_tax > (
        SELECT MAX(ws2.ws_net_paid_inc_tax)
        FROM web_sales ws2
        WHERE ws2.ws_ship_mode_sk = 3
    )                                                            -- scalar subquery filter (single‑row result)
GROUP BY
  i.i_brand,
  r.r_reason_desc,
  s.s_state,
  sm.sm_type
ORDER BY
  total_store_profit DESC
LIMIT 100
