WITH cr_agg AS (
  SELECT
    cr.cr_warehouse_sk,
    td.t_hour,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    ARRAY_AGG(cr.cr_order_number) AS order_numbers
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  WHERE td.t_hour IN (10, 12, 14)
    AND cr.cr_return_amount > 20
    AND cr.cr_return_quantity >= 1
    AND ca.ca_state = 'CA'
  GROUP BY cr.cr_warehouse_sk, td.t_hour
),
wr_agg AS (
  SELECT
    wr.wr_web_page_sk,
    td.t_hour AS hour,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss
  FROM web_returns wr
  JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  WHERE wr.wr_refunded_cash > 100
    AND td.t_hour IN (10, 12, 14)
    AND wr.wr_return_quantity > 0
  GROUP BY wr.wr_web_page_sk, td.t_hour
),
combined AS (
  SELECT
    cr_agg.cr_warehouse_sk,
    w.w_warehouse_name,
    cr_agg.t_hour,
    cr_agg.total_return_amount,
    cr_agg.total_net_loss,
    wr_agg.total_web_return_amount,
    wr_agg.total_web_net_loss,
    cr_agg.order_numbers,
    w.w_county
  FROM cr_agg
  JOIN warehouse w ON cr_agg.cr_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN wr_agg ON cr_agg.t_hour = wr_agg.hour
  LEFT JOIN web_page wp ON wr_agg.wr_web_page_sk = wp.wp_web_page_sk
  WHERE w.w_county = 'Franklin Parish'
)
SELECT
  c.cr_warehouse_sk,
  c.w_warehouse_name,
  c.t_hour,
  c.total_return_amount,
  c.total_net_loss,
  c.total_web_return_amount,
  c.total_web_net_loss,
  (c.total_return_amount + COALESCE(c.total_web_return_amount, 0)) AS total_combined_return_amount,
  (SELECT AVG(total_net_loss) FROM combined) AS avg_total_net_loss,
  RANK() OVER (PARTITION BY c.t_hour ORDER BY c.total_net_loss DESC) AS net_loss_rank,
  o.order_number
FROM combined c
CROSS JOIN UNNEST(c.order_numbers) AS o (order_number)
WHERE (c.total_return_amount + COALESCE(c.total_web_return_amount, 0)) > 500
ORDER BY total_combined_return_amount DESC
LIMIT 100
