WITH all_sales AS (
  SELECT
    'store' AS sales_channel,
    ss.ss_sold_date_sk AS sales_date_sk,
    d.d_date AS sales_date,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid,
    ss.ss_quantity AS quantity
  FROM store_sales ss
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    'catalog' AS sales_channel,
    cs.cs_sold_date_sk AS sales_date_sk,
    d.d_date AS sales_date,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_net_paid AS net_paid,
    cs.cs_quantity AS quantity
  FROM catalog_sales cs
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    'web' AS sales_channel,
    ws.ws_sold_date_sk AS sales_date_sk,
    d.d_date AS sales_date,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_net_profit AS net_profit,
    ws.ws_net_paid AS net_paid,
    ws.ws_quantity AS quantity
  FROM web_sales ws
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),

sales_by_customer AS (
  SELECT
    s.customer_sk,
    CONCAT('CUST_', CAST(s.customer_sk AS VARCHAR)) AS customer_key,
    CONCAT(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS customer_name,
    COALESCE(ca.ca_country, 'UNKNOWN') AS country,
    SUM(s.net_paid) AS total_net_paid,
    SUM(s.net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count,
    MAX(s.sales_date) AS last_purchase_date
  FROM all_sales s
  LEFT JOIN customer c ON s.customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  GROUP BY s.customer_sk, c.c_first_name, c.c_last_name, ca.ca_country
),

all_returns AS (
  SELECT
    'store' AS return_channel,
    sr.sr_returned_date_sk AS return_date_sk,
    d.d_date AS return_date,
    sr.sr_customer_sk AS customer_sk,
    sr.sr_item_sk AS item_sk,
    sr.sr_net_loss AS net_loss
  FROM store_returns sr
  LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    'catalog' AS return_channel,
    cr.cr_returned_date_sk AS return_date_sk,
    d.d_date AS return_date,
    cr.cr_refunded_customer_sk AS customer_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_net_loss AS net_loss
  FROM catalog_returns cr
  LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk

  UNION ALL

  SELECT
    'web' AS return_channel,
    wr.wr_returned_date_sk AS return_date_sk,
    d.d_date AS return_date,
    wr.wr_refunded_customer_sk AS customer_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_net_loss AS net_loss
  FROM web_returns wr
  LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),

returns_by_customer AS (
  SELECT
    r.customer_sk,
    SUM(r.net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    MAX(r.return_date) AS last_return_date
  FROM all_returns r
  GROUP BY r.customer_sk
),

customer_category_sales AS (
  SELECT
    s.customer_sk,
    i.i_category,
    SUM(s.quantity) AS total_quantity,
    SUM(s.net_profit) AS category_net_profit
  FROM all_sales s
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY s.customer_sk, i.i_category
),

top_category_per_customer AS (
  SELECT
    ccs.customer_sk,
    ccs.i_category AS top_category,
    ccs.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY ccs.customer_sk ORDER BY ccs.total_quantity DESC, ccs.category_net_profit DESC) AS rn
  FROM customer_category_sales ccs
),

category_average_profit AS (
  SELECT
    i.i_category,
    AVG(s.net_profit) AS avg_category_profit
  FROM all_sales s
  JOIN item i ON s.item_sk = i.i_item_sk
  GROUP BY i.i_category
),

customers_with_activity AS (
  SELECT customer_sk FROM sales_by_customer
  UNION
  SELECT customer_sk FROM returns_by_customer
)

SELECT
  COALESCE(sbc.customer_key, CONCAT('CUST_', CAST(rbc.customer_sk AS VARCHAR))) AS customer_key,
  COALESCE(sbc.customer_name, 'UNKNOWN') AS customer_name,
  COALESCE(sbc.country, 'UNKNOWN') AS country,
  COALESCE(sbc.total_net_paid, 0) AS total_net_paid,
  COALESCE(sbc.total_net_profit, 0) AS total_net_profit,
  COALESCE(rbc.total_net_loss, 0) AS total_net_loss,
  COALESCE(sbc.total_net_profit, 0) - COALESCE(rbc.total_net_loss, 0) AS net_profit_after_returns,
  COALESCE(sbc.transaction_count, 0) AS transaction_count,
  sbc.last_purchase_date,
  COALESCE(rbc.return_count, 0) AS return_count,
  rbc.last_return_date,
  tc.top_category,
  cap.avg_category_profit,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(sbc.country, 'UNKNOWN') ORDER BY (COALESCE(sbc.total_net_profit, 0) - COALESCE(rbc.total_net_loss, 0)) DESC) AS country_rank,
  CASE
    WHEN sbc.last_purchase_date IS NULL THEN 'No Purchases'
    WHEN sbc.last_purchase_date >= DATE '2023-01-01' THEN 'Recent'
    ELSE 'Old'
  END AS purchase_recency,
  (SELECT MAX(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_bill_customer_sk = COALESCE(sbc.customer_sk, rbc.customer_sk)) AS max_web_sales_price
FROM sales_by_customer sbc
FULL OUTER JOIN returns_by_customer rbc ON sbc.customer_sk = rbc.customer_sk
LEFT JOIN (
  SELECT customer_sk, top_category FROM top_category_per_customer WHERE rn = 1
) tc ON COALESCE(sbc.customer_sk, rbc.customer_sk) = tc.customer_sk
LEFT JOIN category_average_profit cap ON tc.top_category = cap.i_category
WHERE COALESCE(sbc.customer_sk, rbc.customer_sk) IN (SELECT customer_sk FROM customers_with_activity)
  AND (
    (COALESCE(sbc.country, 'UNKNOWN') = 'United States' AND COALESCE(sbc.total_net_paid, 0) > 1000)
    OR COALESCE(rbc.return_count, 0) > 5
  )
ORDER BY net_profit_after_returns DESC
LIMIT 100
