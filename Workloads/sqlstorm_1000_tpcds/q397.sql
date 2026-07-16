SELECT
    d.d_year,
    s.s_state,
    i.i_brand,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year BETWEEN 2001 AND 2002
  AND s.s_state IN ('CA','TX','WA')
  AND i.i_brand IN ('Brand#34','Brand#21')
GROUP BY d.d_year, s.s_state, i.i_brand
ORDER BY total_profit DESC
LIMIT 100
