SELECT i.i_category, d.d_year, SUM(ss.ss_net_paid_inc_tax) AS total_sales
FROM store_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
GROUP BY i.i_category, d.d_year
ORDER BY total_sales DESC
LIMIT 10
