/*
  Goal: Compute total net profit, return losses, and catalog return losses per store and hour of day,
  differentiate between store and web channels, rank stores by net contribution, and classify profit levels.
*/
WITH
  sales_agg AS (
    SELECT
      s.s_store_id AS store_id,
      t_s.t_hour AS hour_of_day,
      'store' AS channel,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_net_profit) AS total_net_profit,
      COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
      SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN time_dim t_s ON ss.ss_sold_time_sk = t_s.t_time_sk
    INNER JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    GROUP BY s.s_store_id, t_s.t_hour
  ),
  returns_agg AS (
    SELECT
      s.s_store_id AS store_id,
      t_r.t_hour AS hour_of_day,
      'store' AS channel,
      SUM(sr.sr_net_loss) AS total_return_loss,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
      SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN time_dim t_r ON sr.sr_return_time_sk = t_r.t_time_sk
    INNER JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    INNER JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY s.s_store_id, t_r.t_hour
  ),
  catalog_returns_agg AS (
    SELECT
      t_c.t_hour AS hour_of_day,
      SUM(cr.cr_net_loss) AS total_catalog_loss,
      COUNT(*) AS total_catalog_returns
    FROM catalog_returns cr
    INNER JOIN time_dim t_c ON cr.cr_returned_time_sk = t_c.t_time_sk
    INNER JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    INNER JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    GROUP BY t_c.t_hour
  ),
  web_sales_agg AS (
    SELECT
      NULL AS store_id,
      t_w.t_hour AS hour_of_day,
      'web' AS channel,
      SUM(ws.ws_net_paid) AS total_net_paid,
      SUM(ws.ws_net_profit) AS total_net_profit,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    INNER JOIN time_dim t_w ON ws.ws_sold_time_sk = t_w.t_time_sk
    INNER JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    GROUP BY t_w.t_hour
  ),
  combined_sales AS (
    SELECT
      store_id,
      hour_of_day,
      channel,
      total_net_paid,
      total_net_profit,
      distinct_tickets AS distinct_transactions,
      total_quantity
    FROM sales_agg
    UNION ALL
    SELECT
      store_id,
      hour_of_day,
      channel,
      total_net_paid,
      total_net_profit,
      distinct_orders AS distinct_transactions,
      total_quantity
    FROM web_sales_agg
  )
SELECT
  cs.store_id,
  cs.hour_of_day,
  cs.channel,
  cs.total_net_paid,
  cs.total_net_profit,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  COALESCE(cr.total_catalog_loss, 0) AS total_catalog_loss,
  (cs.total_net_profit - COALESCE(r.total_return_loss, 0) - COALESCE(cr.total_catalog_loss, 0)) AS net_contribution,
  CASE
    WHEN cs.total_net_profit > 10000 THEN 'HIGH'
    WHEN cs.total_net_profit BETWEEN 5000 AND 10000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  (SELECT AVG(total_net_profit) FROM combined_sales) AS avg_net_profit_overall,
  RANK() OVER (
    PARTITION BY cs.channel
    ORDER BY (cs.total_net_profit - COALESCE(r.total_return_loss, 0) - COALESCE(cr.total_catalog_loss, 0)) DESC
  ) AS profit_rank,
  cs.distinct_transactions
FROM combined_sales cs
LEFT JOIN returns_agg r
  ON cs.store_id = r.store_id
  AND cs.hour_of_day = r.hour_of_day
  AND cs.channel = r.channel
LEFT JOIN catalog_returns_agg cr
  ON cs.hour_of_day = cr.hour_of_day
WHERE cs.total_net_paid > 0
ORDER BY cs.channel, net_contribution DESC
LIMIT 100
