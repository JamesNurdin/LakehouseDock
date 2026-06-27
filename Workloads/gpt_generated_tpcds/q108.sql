WITH sales_by_store_month AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_moy,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_ext_list_price) = 0 THEN 0
         ELSE SUM(ss.ss_ext_discount_amt) / SUM(ss.ss_ext_list_price)
    END AS avg_discount_pct
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
  WHERE d.d_date >= DATE '2001-01-01' AND d.d_date < DATE '2002-01-01'
  GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy
),
ranked_sales AS (
  SELECT
    s_store_id,
    s_store_name,
    d_year,
    d_moy,
    total_sales,
    total_profit,
    avg_discount_pct,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy ORDER BY total_profit DESC) AS rn
  FROM sales_by_store_month
)
SELECT
  s_store_id,
  s_store_name,
  d_year,
  d_moy,
  total_sales,
  total_profit,
  avg_discount_pct
FROM ranked_sales
WHERE rn <= 5
ORDER BY d_year, d_moy, total_profit DESC
