WITH sales_with_details AS (
   SELECT
       s.s_store_name,
       CONCAT(s.s_city, ', ', s.s_state) AS store_location,
       d.d_year,
       d.d_month_seq,
       ss.ss_ext_sales_price,
       ss.ss_net_profit,
       ca.ca_zip,
       ca.ca_city,
       CASE
          WHEN ss.ss_net_profit > 1000 THEN 'HIGH'
          WHEN ss.ss_net_profit > 100 THEN 'MEDIUM'
          ELSE 'LOW'
       END AS profit_category,
       regexp_extract(ca.ca_zip, '^([0-9]{2})', 1) AS zip_region
   FROM store_sales ss
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN date_dim d
     ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE s.s_store_name LIKE '%Store%'
     AND regexp_like(ca.ca_zip, '^[0-9]{5}$')
)
SELECT
    profit_category,
    zip_region,
    store_location,
    d_year,
    d_month_seq,
    COUNT(*) AS sales_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    MAX(CASE WHEN ca_city LIKE 'San%' THEN ca_city END) AS example_san_city
FROM sales_with_details
GROUP BY profit_category, zip_region, store_location, d_year, d_month_seq
HAVING SUM(ss_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 100
