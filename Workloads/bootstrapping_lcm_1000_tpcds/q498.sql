WITH base AS (
  SELECT
    s.s_store_id,
    d_sold.d_current_month,
    p.p_promo_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_sales_price) AS avg_price,
    SUM(ss.ss_net_profit) AS total_profit,
    MIN(d_closed.d_date) AS store_closed_date,
    MIN(d_start.d_date) AS promo_start_date,
    MIN(d_end.d_date) AS promo_end_date
  FROM store_sales ss
  JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
  JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
  LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
  WHERE d_sold.d_year = 2022
    AND p.p_discount_active = 'Y'
  GROUP BY s.s_store_id, d_sold.d_current_month, p.p_promo_id
), ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
  FROM base
)
SELECT
  s_store_id,
  d_current_month,
  p_promo_id,
  total_sales,
  total_quantity,
  avg_price,
  total_profit,
  store_closed_date,
  promo_start_date,
  promo_end_date,
  sales_rank
FROM ranked
WHERE sales_rank <= 3
ORDER BY s_store_id, d_current_month, sales_rank
