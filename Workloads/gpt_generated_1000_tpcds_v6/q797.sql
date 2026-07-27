WITH
  joined_data AS (
    SELECT
      w.w_warehouse_id AS w_warehouse_id,
      w.w_county AS w_county,
      r.r_reason_desc AS r_reason_desc,
      cr.cr_return_amount AS cr_return_amount,
      cr.cr_return_quantity AS cr_return_quantity,
      ws.ws_net_paid AS ws_net_paid,
      ws.ws_net_profit AS ws_net_profit,
      wp.wp_autogen_flag AS wp_autogen_flag,
      wp.wp_image_count AS wp_image_count,
      ws.ws_ship_date_sk AS ws_ship_date_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
     AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE w.w_county IN ('Bronx County', 'Franklin Parish')
      AND w.w_street_type = 'Ave'
      AND wp.wp_autogen_flag = 'Y'
      AND wp.wp_image_count >= 3
      AND ws.ws_ship_date_sk BETWEEN 2451800 AND 2452800
      AND ws.ws_bill_customer_sk > 4000000
      AND cr.cr_return_quantity > 0
  ),

  agg1 AS (
    SELECT
      w_warehouse_id,
      r_reason_desc,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(ws_net_paid) AS total_web_paid,
      COUNT(*) AS txn_count
    FROM joined_data
    GROUP BY w_warehouse_id, r_reason_desc
  ),

  agg2 AS (
    SELECT
      w_warehouse_id,
      r_reason_desc,
      SUM(cr_return_amount) * 0.9 AS adj_return_amount,
      SUM(ws_net_paid) * 1.1 AS adj_web_paid,
      COUNT(*) AS txn_count
    FROM joined_data
    WHERE cr_return_amount > 100
      AND ws_net_paid > 0
    GROUP BY w_warehouse_id, r_reason_desc
    HAVING SUM(cr_return_amount) > 1000
  )

SELECT
  final.w_warehouse_id,
  final.r_reason_desc,
  SUM(final.total_return_amount) AS sum_return_amount,
  AVG(final.total_web_paid) AS avg_web_paid,
  SUM(final.txn_count) AS total_txns
FROM (
  SELECT w_warehouse_id, r_reason_desc, total_return_amount, total_web_paid, txn_count
  FROM agg1
  UNION ALL
  SELECT w_warehouse_id, r_reason_desc, adj_return_amount AS total_return_amount, adj_web_paid AS total_web_paid, txn_count
  FROM agg2
) AS final
GROUP BY final.w_warehouse_id, final.r_reason_desc
HAVING SUM(final.total_return_amount) > 5000
ORDER BY sum_return_amount DESC
LIMIT 100
