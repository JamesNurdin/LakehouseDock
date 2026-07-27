WITH sales AS (
   SELECT
       ss.ss_sold_date_sk AS sold_date_sk,
       ca.ca_state,
       ca.ca_city,
       ca.ca_zip,
       d.d_year,
       d.d_month_seq,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_quantity) AS total_qty,
       AVG(ss.ss_ext_tax) AS avg_tax
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year = 2002
     AND REGEXP_LIKE(ca.ca_zip, '^9[0-9]{4}$')
     AND ca.ca_state LIKE 'C%'
   GROUP BY ss.ss_sold_date_sk, ca.ca_state, ca.ca_city, ca.ca_zip, d.d_year, d.d_month_seq
),
inventory_agg AS (
   SELECT
       inv.inv_date_sk AS inv_date_sk,
       SUM(inv.inv_quantity_on_hand) AS total_inventory
   FROM inventory inv
   GROUP BY inv.inv_date_sk
)
SELECT
   s.ca_state,
   s.d_year,
   s.d_month_seq,
   CONCAT(s.ca_city, ', ', s.ca_state) AS city_state,
   REGEXP_EXTRACT(s.ca_zip, '(\\d{5})') AS zip5,
   s.total_sales,
   s.total_qty,
   s.avg_tax,
   i.total_inventory,
   ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM sales s
JOIN inventory_agg i ON s.sold_date_sk = i.inv_date_sk
ORDER BY s.total_sales DESC
LIMIT 100
