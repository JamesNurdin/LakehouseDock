WITH store_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'store' AS channel,
    i.i_category AS product_category,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'catalog' AS channel,
    i.i_category AS product_category,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
  GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    'web' AS channel,
    i.i_category AS product_category,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
  GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
  d_year,
  d_month_seq,
  channel,
  product_category,
  total_sales_profit,
  total_return_loss,
  total_sales_profit - total_return_loss AS net_profit_after_returns,
  distinct_customers
FROM (
  SELECT * FROM store_agg
  UNION ALL
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
) AS combined
ORDER BY d_year, d_month_seq, channel, product_category
