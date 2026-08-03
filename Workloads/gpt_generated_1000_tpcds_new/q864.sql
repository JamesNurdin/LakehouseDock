WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    WHERE ss_quantity > 0
  ),
  base_join AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_customer_sk,
      ss.ss_store_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_sales_price,
      d.d_year,
      i.i_brand,
      c.c_first_name,
      c.c_last_name,
      s.s_store_name,
      inv.inv_quantity_on_hand,
      ws.ws_net_paid,
      wp.wp_url,
      CASE WHEN ss.ss_quantity > 10 THEN 'High' ELSE 'Low' END AS qty_level,
      ARRAY[ss.ss_quantity, ss.ss_sales_price] AS qty_price_arr
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
  ),
  call_center_join AS (
    SELECT
      cc.cc_call_center_id,
      d2.d_year AS open_year,
      cc.cc_name,
      cc.cc_employees
    FROM call_center cc
    JOIN date_dim d2 ON cc.cc_open_date_sk = d2.d_date_sk
  ),
  store_ret_join AS (
    SELECT
      sr.sr_ticket_number,
      r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  ),
  web_ret_join AS (
    SELECT
      wr.wr_order_number,
      r2.r_reason_desc AS web_reason
    FROM web_returns wr
    JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
  )
SELECT
  final_set.d_year,
  final_set.i_brand,
  final_set.s_store_name,
  final_set.c_first_name,
  final_set.c_last_name,
  final_set.qty_level,
  final_set.inv_quantity_on_hand,
  final_set.ws_net_paid,
  final_set.wp_url,
  final_set.lag_qty,
  final_set.cc_name,
  final_set.cc_employees,
  final_set.r_reason_desc,
  final_set.web_reason,
  final_set.qty_price_val
FROM (
  SELECT
    bj.d_year,
    bj.i_brand,
    bj.s_store_name,
    bj.c_first_name,
    bj.c_last_name,
    bj.qty_level,
    bj.inv_quantity_on_hand,
    bj.ws_net_paid,
    bj.wp_url,
    LAG(bj.ss_quantity) OVER (PARTITION BY bj.ss_item_sk ORDER BY bj.d_year) AS lag_qty,
    cc.cc_name,
    cc.cc_employees,
    sr.r_reason_desc,
    wr.web_reason,
    u.val AS qty_price_val
  FROM (
    SELECT * FROM base_join
  ) bj
  LEFT JOIN call_center_join cc ON bj.d_year = cc.open_year
  LEFT JOIN store_ret_join sr ON bj.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN web_ret_join wr ON bj.ss_ticket_number = wr.wr_order_number
  CROSS JOIN UNNEST(bj.qty_price_arr) AS u(val)
  WHERE bj.qty_level = 'High'
    AND NOT EXISTS (
      SELECT 1 FROM store_returns sr2 WHERE sr2.sr_ticket_number = bj.ss_ticket_number
    )

  UNION DISTINCT

  SELECT
    bj.d_year,
    bj.i_brand,
    bj.s_store_name,
    bj.c_first_name,
    bj.c_last_name,
    bj.qty_level,
    bj.inv_quantity_on_hand,
    bj.ws_net_paid,
    bj.wp_url,
    LAG(bj.ss_quantity) OVER (PARTITION BY bj.ss_item_sk ORDER BY bj.d_year) AS lag_qty,
    cc.cc_name,
    cc.cc_employees,
    sr.r_reason_desc,
    wr.web_reason,
    NULL AS qty_price_val
  FROM (
    SELECT * FROM base_join
  ) bj
  LEFT JOIN call_center_join cc ON bj.d_year = cc.open_year
  LEFT JOIN store_ret_join sr ON bj.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN web_ret_join wr ON bj.ss_ticket_number = wr.wr_order_number
  WHERE bj.qty_level = 'High'
    AND NOT EXISTS (
      SELECT 1 FROM store_returns sr2 WHERE sr2.sr_ticket_number = bj.ss_ticket_number
    )
) final_set
ORDER BY final_set.d_year DESC, final_set.i_brand
LIMIT 100
