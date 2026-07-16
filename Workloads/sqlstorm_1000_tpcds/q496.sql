WITH unified_sales AS (
  SELECT 
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_call_center_sk AS call_center_sk,
    cs.cs_warehouse_sk AS warehouse_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_order_number AS order_number,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT 
    ss.ss_sold_date_sk AS sold_date_sk,
    NULL AS call_center_sk,
    ss.ss_store_sk AS warehouse_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_ticket_number AS order_number,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT 
    ws.ws_sold_date_sk AS sold_date_sk,
    NULL AS call_center_sk,
    ws.ws_warehouse_sk AS warehouse_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_order_number AS order_number,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    'web' AS channel
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IS NOT NULL
),
agg_sales_raw AS (
  SELECT 
    d.d_year,
    us.channel,
    COUNT(DISTINCT us.order_number) AS orders,
    SUM(us.quantity) AS total_quantity,
    SUM(us.net_paid) AS total_net_paid,
    SUM(us.net_profit) AS total_net_profit,
    AVG(us.net_paid) AS avg_net_paid
  FROM unified_sales us
  JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, us.channel
),
agg_sales AS (
  SELECT
    r.*,
    ROW_NUMBER() OVER (PARTITION BY r.channel ORDER BY r.total_net_profit DESC) AS profit_rank
  FROM agg_sales_raw r
),
channel_stats AS (
  SELECT 
    channel,
    SUM(total_net_profit) AS overall_profit,
    AVG(total_net_paid) AS overall_avg_paid
  FROM agg_sales
  GROUP BY channel
),
customer_last_purchase AS (
  SELECT 
    c.c_customer_sk,
    c.c_customer_id,
    MAX(d.d_date) AS last_purchase_date,
    MAX(CASE WHEN us.channel = 'catalog' THEN us.net_paid END) AS max_catalog_spend,
    MAX(CASE WHEN us.channel = 'store' THEN us.net_paid END) AS max_store_spend,
    MAX(CASE WHEN us.channel = 'web' THEN us.net_paid END) AS max_web_spend
  FROM customer c
  LEFT JOIN unified_sales us ON c.c_customer_sk = us.customer_sk
  LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
  GROUP BY c.c_customer_sk, c.c_customer_id
),
high_profit_items AS (
  SELECT 
    i.i_item_sk,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    SUM(us.net_profit) AS item_total_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(us.net_profit) DESC) AS profit_rank
  FROM unified_sales us
  JOIN item i ON us.item_sk = i.i_item_sk
  JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
  GROUP BY i.i_item_sk, i.i_product_name, i.i_category, i.i_brand
  HAVING SUM(us.net_profit) > 10000
)

SELECT
  COALESCE(a.d_year, -1) AS year,
  COALESCE(a.channel, 'UNKNOWN') AS sales_channel,
  a.orders,
  a.total_quantity,
  a.total_net_paid,
  a.total_net_profit,
  a.avg_net_paid,
  a.profit_rank,
  cs.overall_profit,
  cs.overall_avg_paid,
  CASE 
    WHEN cs.overall_profit > 0 THEN (a.total_net_profit / cs.overall_profit) * 100 
    ELSE NULL 
  END AS profit_pct_of_channel,
  CONCAT(a.channel, '-', CAST(a.d_year AS VARCHAR)) AS channel_year_label,
  COALESCE(a.orders, 0) AS safe_orders,
  SUM(a.total_net_profit) OVER (PARTITION BY a.channel) AS total_channel_profit_to_date,
  (SELECT MAX(us2.net_paid)
   FROM unified_sales us2
   JOIN date_dim d2 ON us2.sold_date_sk = d2.d_date_sk
   WHERE us2.channel = a.channel AND d2.d_year = a.d_year) AS max_net_paid_in_year_channel
FROM agg_sales a
FULL OUTER JOIN channel_stats cs ON a.channel = cs.channel
ORDER BY sales_channel, year
