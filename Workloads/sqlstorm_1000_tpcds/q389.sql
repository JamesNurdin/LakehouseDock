WITH date_month AS (
  SELECT d_date_sk, date_trunc('month', CAST(d_date AS timestamp)) AS sales_month, d_year
  FROM date_dim
),
catalog AS (
  SELECT
    dm.sales_month,
    i.i_category,
    p.p_promo_name,
    SUM(cs.cs_net_profit) AS net_profit,
    SUM(cs.cs_ext_sales_price) AS revenue,
    COUNT(*) AS sales_cnt
  FROM catalog_sales cs
  JOIN date_month dm ON cs.cs_sold_date_sk = dm.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY dm.sales_month, i.i_category, p.p_promo_name
),
store AS (
  SELECT
    dm.sales_month,
    i.i_category,
    p.p_promo_name,
    SUM(ss.ss_net_profit) AS net_profit,
    SUM(ss.ss_ext_sales_price) AS revenue,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN date_month dm ON ss.ss_sold_date_sk = dm.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY dm.sales_month, i.i_category, p.p_promo_name
),
web AS (
  SELECT
    dm.sales_month,
    i.i_category,
    p.p_promo_name,
    SUM(ws.ws_net_profit) AS net_profit,
    SUM(ws.ws_ext_sales_price) AS revenue,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN date_month dm ON ws.ws_sold_date_sk = dm.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY dm.sales_month, i.i_category, p.p_promo_name
),
combined AS (
  SELECT
    sales_month,
    i_category,
    p_promo_name,
    SUM(net_profit) AS total_net_profit,
    SUM(revenue) AS total_revenue,
    SUM(sales_cnt) AS total_sales_cnt
  FROM (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM store
    UNION ALL
    SELECT * FROM web
  ) u
  GROUP BY sales_month, i_category, p_promo_name
)
SELECT
  sales_month,
  i_category,
  p_promo_name,
  total_net_profit,
  total_revenue,
  total_sales_cnt,
  total_net_profit / NULLIF(total_revenue, 0) AS profit_margin,
  ROW_NUMBER() OVER (PARTITION BY sales_month ORDER BY total_net_profit DESC) AS profit_rank
FROM combined
WHERE total_sales_cnt > 100
ORDER BY sales_month, profit_rank
LIMIT 100
