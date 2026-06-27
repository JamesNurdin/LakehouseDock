WITH store_sales_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    s.s_store_name,
    sum(ss.ss_quantity) AS total_sales_qty,
    sum(ss.ss_net_profit) AS total_sales_profit,
    sum(ss.ss_ext_discount_amt) AS total_sales_discount,
    sum(p.p_cost) AS total_promo_cost,
    count(distinct ss.ss_promo_sk) AS promo_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_moy, s.s_store_name
),
store_returns_agg AS (
  SELECT
    d.d_year,
    d.d_moy,
    s.s_store_name,
    sum(sr.sr_return_quantity) AS total_return_qty,
    sum(sr.sr_net_loss) AS total_return_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, d.d_moy, s.s_store_name
)
SELECT
  ss.d_year,
  ss.d_moy,
  ss.s_store_name,
  ss.total_sales_qty,
  ss.total_sales_profit,
  ss.total_sales_discount,
  ss.total_promo_cost,
  ss.promo_count,
  COALESCE(sr.total_return_qty, 0) AS total_return_qty,
  COALESCE(sr.total_return_loss, 0) AS total_return_loss,
  (ss.total_sales_profit - COALESCE(sr.total_return_loss, 0)) AS net_profit_after_returns
FROM store_sales_agg ss
LEFT JOIN store_returns_agg sr
  ON ss.d_year = sr.d_year
  AND ss.d_moy = sr.d_moy
  AND ss.s_store_name = sr.s_store_name
ORDER BY ss.d_year, ss.d_moy, ss.s_store_name
