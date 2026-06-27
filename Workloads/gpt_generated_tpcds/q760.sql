SELECT
    s.s_store_id,
    s.s_store_name,
    d_sale.d_year,
    d_sale.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_promo_sk) AS distinct_promos_used,
    AVG(ss.ss_quantity) AS avg_quantity_per_sale,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_month_rank
FROM store_sales ss
JOIN date_dim d_sale
  ON ss.ss_sold_date_sk = d_sale.d_date_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
LEFT JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN date_dim d_store_closed
  ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sale.d_year = 2000
  AND (s.s_closed_date_sk IS NULL OR d_store_closed.d_date > d_sale.d_date)
  AND (p.p_promo_sk IS NULL OR (d_sale.d_date BETWEEN d_promo_start.d_date AND d_promo_end.d_date))
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sale.d_year,
    d_sale.d_month_seq
ORDER BY total_sales DESC
LIMIT 10
