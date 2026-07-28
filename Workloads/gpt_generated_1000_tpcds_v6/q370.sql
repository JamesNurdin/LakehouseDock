WITH
  joined_data AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_state,
      r.r_reason_desc,
      r2.r_reason_desc AS cr_reason_desc,
      td.t_hour,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      COALESCE(sr.sr_net_loss, 0) AS sr_net_loss,
      COALESCE(cr.cr_net_loss, 0) AS cr_net_loss,
      inv.inv_quantity_on_hand,
      w.w_warehouse_name
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_item_sk = sr.sr_item_sk
     AND ss.ss_store_sk = sr.sr_store_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_returns cr
      ON ss.ss_ticket_number = cr.cr_order_number
     AND cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
      td.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND (r.r_reason_desc LIKE '%warranty%' OR r2.r_reason_desc LIKE '%warranty%')
      AND inv.inv_quantity_on_hand > 0
  ),
  sales_agg AS (
    SELECT
      s_store_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_paid) AS total_net_paid
    FROM joined_data
    GROUP BY s_store_sk
  ),
  loss_agg AS (
    SELECT
      s_store_sk,
      SUM(sr_net_loss + cr_net_loss) AS total_return_loss,
      SUM(inv_quantity_on_hand) AS total_inventory
    FROM joined_data
    GROUP BY s_store_sk
  ),
  combined AS (
    SELECT s_store_sk, total_sales AS metric, 'sales' AS metric_type FROM sales_agg
    UNION ALL
    SELECT s_store_sk, total_return_loss AS metric, 'return_loss' AS metric_type FROM loss_agg
  )
SELECT
  c.s_store_sk,
  MAX(s.s_store_name) AS store_name,
  c.metric_type,
  AVG(c.metric) AS avg_metric
FROM combined c
JOIN store s ON c.s_store_sk = s.s_store_sk
WHERE EXISTS (
  SELECT 1 FROM sales_agg sa
  WHERE sa.s_store_sk = c.s_store_sk AND sa.total_sales > 100000
)
GROUP BY c.s_store_sk, c.metric_type
HAVING AVG(c.metric) > 5000
ORDER BY avg_metric DESC, c.metric_type
