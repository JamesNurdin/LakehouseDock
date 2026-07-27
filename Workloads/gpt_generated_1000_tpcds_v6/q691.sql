WITH
  sales_agg AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk,
      SUM(cs.cs_net_paid)               AS total_cs_net_paid,
      SUM(cs.cs_ext_ship_cost)          AS total_cs_ship_cost
    FROM catalog_sales cs
    JOIN call_center cc   ON cs.cs_call_center_sk   = cc.cc_call_center_sk
    JOIN catalog_page cp  ON cs.cs_catalog_page_sk  = cp.cp_catalog_page_sk
    JOIN warehouse w      ON cs.cs_warehouse_sk    = w.w_warehouse_sk
    JOIN time_dim td      ON cs.cs_sold_time_sk    = td.t_time_sk
    WHERE w.w_gmt_offset = -6.00
      AND cc.cc_state    = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
      cs.cs_order_number,
      cs.cs_sold_time_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_warehouse_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_order_number,
      SUM(cr.cr_return_amount) AS total_return_amount,
      COUNT(*)                AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour >= 12
    GROUP BY cr.cr_order_number
  ),
  store_metrics AS (
    SELECT
      ss.ss_sold_time_sk,
      SUM(ss.ss_net_paid)                AS total_store_net_paid,
      SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amt,
      COUNT(sr.sr_ticket_number)         AS store_return_cnt
    FROM store_sales ss
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
         AND ss.ss_item_sk    = sr.sr_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 20
    GROUP BY ss.ss_sold_time_sk
  )
SELECT
  s.cs_order_number,
  s.total_cs_net_paid,
  r.total_return_amount,
  sm.total_store_net_paid,
  sm.total_store_return_amt,
  (
    SELECT AVG(w2.w_gmt_offset)
    FROM warehouse w2
    WHERE w2.w_state = 'TX'
  ) AS avg_tx_gmt_offset
FROM sales_agg s
LEFT JOIN returns_agg r   ON s.cs_order_number = r.cr_order_number
JOIN time_dim td          ON s.cs_sold_time_sk = td.t_time_sk
LEFT JOIN store_metrics sm ON td.t_time_sk = sm.ss_sold_time_sk
WHERE s.total_cs_net_paid > 500
  AND (r.total_return_amount IS NULL OR r.total_return_amount < 1000)
  AND sm.total_store_net_paid > 300
ORDER BY s.total_cs_net_paid DESC
LIMIT 50
