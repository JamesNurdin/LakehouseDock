SELECT d_year, SUM(ss_net_paid) AS total_net_paid
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2000
GROUP BY d_year
ORDER BY total_net_paid DESC
