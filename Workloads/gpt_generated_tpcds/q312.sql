WITH store_sales_agg AS (
  SELECT
    promotion.p_promo_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    store_sales.ss_net_profit
  FROM store_sales
  JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
  JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
  WHERE promotion.p_discount_active = 'Y'
    AND date_dim.d_date >= DATE '2001-01-01'
    AND date_dim.d_date < DATE '2002-01-01'
),
catalog_sales_agg AS (
  SELECT
    promotion.p_promo_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    catalog_sales.cs_net_profit
  FROM catalog_sales
  JOIN promotion ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
  JOIN date_dim ON catalog_sales.cs_sold_date_sk = date_dim.d_date_sk
  WHERE promotion.p_discount_active = 'Y'
    AND date_dim.d_date >= DATE '2001-01-01'
    AND date_dim.d_date < DATE '2002-01-01'
),
web_sales_agg AS (
  SELECT
    promotion.p_promo_name,
    date_dim.d_year,
    date_dim.d_month_seq,
    web_sales.ws_net_profit
  FROM web_sales
  JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
  JOIN date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
  WHERE promotion.p_discount_active = 'Y'
    AND date_dim.d_date >= DATE '2001-01-01'
    AND date_dim.d_date < DATE '2002-01-01'
),
combined AS (
  SELECT p_promo_name, d_year, d_month_seq, ss_net_profit AS net_profit FROM store_sales_agg
  UNION ALL
  SELECT p_promo_name, d_year, d_month_seq, cs_net_profit FROM catalog_sales_agg
  UNION ALL
  SELECT p_promo_name, d_year, d_month_seq, ws_net_profit FROM web_sales_agg
)
SELECT
  p_promo_name,
  d_year,
  d_month_seq,
  SUM(net_profit) AS total_net_profit
FROM combined
GROUP BY p_promo_name, d_year, d_month_seq
ORDER BY total_net_profit DESC
LIMIT 10
