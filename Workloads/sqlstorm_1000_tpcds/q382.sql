SELECT
    d.d_year,
    s.s_store_name,
    i.i_category,
    p.p_promo_name,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
WHERE d.d_year BETWEEN 1999 AND 2001
  AND s.s_state = 'TN'
  AND i.i_color = 'BLUE'
GROUP BY GROUPING SETS (
    (d.d_year, s.s_store_name, i.i_category, p.p_promo_name),
    (d.d_year, s.s_store_name, i.i_category),
    (d.d_year, s.s_store_name)
)
ORDER BY total_net_paid DESC
LIMIT 100
