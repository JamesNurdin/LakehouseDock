WITH avg_year_net AS (
   SELECT AVG(ss2.ss_net_paid) AS avg_net
   FROM store_sales ss2
   JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
   WHERE d2.d_year = 2001
)
SELECT
   i.i_item_id,
   i.i_product_name,
   d.d_year,
   d.d_month_seq,
   t.t_hour,
   cc.cc_name,
   SUM(ss.ss_net_paid) AS total_net_paid,
   AVG(ss.ss_quantity) AS avg_quantity,
   COUNT(*) AS sales_count,
   MIN(ss.ss_sales_price) AS min_sales_price,
   MAX(ss.ss_sales_price) AS max_sales_price,
   (SELECT avg_net FROM avg_year_net) AS year_avg_net_paid,
   SUM(ss.ss_net_paid) - (SELECT avg_net FROM avg_year_net) AS net_paid_above_avg
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND d.d_moy = 12
  AND i.i_class = 'furniture'
  AND t.t_hour BETWEEN 9 AND 17
  AND cc.cc_company_name = 'cally'
GROUP BY
   i.i_item_id,
   i.i_product_name,
   d.d_year,
   d.d_month_seq,
   t.t_hour,
   cc.cc_name
ORDER BY total_net_paid DESC
LIMIT 100
