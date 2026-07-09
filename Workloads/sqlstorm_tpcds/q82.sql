WITH catalog_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_category_id,
    SUM(cs.cs_ext_sales_price) AS sales,
    SUM(cs.cs_net_profit) AS profit,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
    COUNT(DISTINCT cs.cs_order_number) AS orders
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, i.i_category, i.i_category_id
),
store_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_category_id,
    SUM(ss.ss_ext_sales_price) AS sales,
    SUM(ss.ss_net_profit) AS profit,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
    COUNT(DISTINCT ss.ss_ticket_number) AS orders
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, i.i_category, i.i_category_id
),
web_sales_agg AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_category_id,
    SUM(ws.ws_ext_sales_price) AS sales,
    SUM(ws.ws_net_profit) AS profit,
    SUM(COALESCE(p.p_cost, 0)) AS promo_cost,
    COUNT(DISTINCT ws.ws_order_number) AS orders
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY d.d_year, i.i_category, i.i_category_id
),
combined_sales AS (
  SELECT
    d_year,
    i_category,
    i_category_id,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    SUM(promo_cost) AS total_promo_cost,
    SUM(orders) AS total_orders
  FROM (
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
  ) t
  GROUP BY d_year, i_category, i_category_id
)
SELECT
  d_year,
  i_category,
  i_category_id,
  total_sales,
  total_profit,
  total_promo_cost,
  total_orders,
  total_sales / NULLIF(total_orders, 0) AS avg_sales_per_order,
  CASE WHEN total_sales = 0 THEN 0 ELSE (total_profit - total_promo_cost) / total_sales END AS profit_margin_adj,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
  AVG(total_sales) OVER (PARTITION BY i_category ORDER BY d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3yr_sales
FROM combined_sales
WHERE d_year BETWEEN 1998 AND 2002
ORDER BY d_year, sales_rank
