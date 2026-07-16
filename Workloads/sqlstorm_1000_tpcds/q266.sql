WITH store_agg AS (
  SELECT
    s.s_store_name AS store_name,
    d.d_year AS sales_year,
    i.i_category AS category,
    i.i_class AS class_name,
    p.p_promo_name AS promo_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY s.s_store_name, d.d_year, i.i_category, i.i_class, p.p_promo_name
),
store_ret AS (
  SELECT
    s.s_store_name AS store_name,
    d.d_year AS sales_year,
    SUM(sr.sr_net_loss) AS total_loss,
    COUNT(*) AS return_cnt
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY s.s_store_name, d.d_year
)
SELECT
  sa.store_name,
  sa.sales_year,
  sa.category,
  sa.class_name,
  COALESCE(sa.promo_name, 'No Promo') AS promo_name,
  sa.total_sales,
  sa.total_profit,
  COALESCE(sr.total_loss, 0) AS total_loss,
  (sa.total_profit - COALESCE(sr.total_loss, 0)) AS net_profit,
  sa.order_cnt,
  COALESCE(sr.return_cnt, 0) AS return_cnt
FROM store_agg sa
LEFT JOIN store_ret sr
  ON sa.store_name = sr.store_name AND sa.sales_year = sr.sales_year
ORDER BY net_profit DESC
LIMIT 100
