SELECT
  s.s_store_name,
  w.web_class,
  cd.cd_gender,
  d.d_year,
  d.d_month_seq,
  SUM(i.inv_quantity_on_hand) AS total_qty,
  AVG(i.inv_quantity_on_hand) AS avg_qty,
  COUNT(DISTINCT c.c_customer_sk) AS cust_cnt,
  MIN(d.d_date) AS min_date,
  MAX(d.d_date) AS max_date
FROM date_dim d
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
JOIN customer c ON c.c_first_shipto_date_sk = d.d_date_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'M'
  AND c.c_birth_month = 5
  AND w.web_tax_percentage > 0.05
  AND i.inv_quantity_on_hand > 0
GROUP BY s.s_store_name, w.web_class, cd.cd_gender, d.d_year, d.d_month_seq
HAVING SUM(i.inv_quantity_on_hand) > 1000
   AND COUNT(DISTINCT c.c_customer_sk) >= 10
ORDER BY total_qty DESC
LIMIT 100
