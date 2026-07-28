WITH year_dates AS (
   SELECT d_date_sk, d_year
   FROM date_dim
   WHERE d_year = 2001
)
SELECT state,
       total_profit,
       source
FROM (
   SELECT ca.ca_state AS state,
          SUM(cs.cs_net_profit) AS total_profit,
          'Catalog' AS source
   FROM catalog_sales cs
   JOIN year_dates yd ON cs.cs_sold_date_sk = yd.d_date_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cs.cs_list_price > 80
     AND w.w_gmt_offset = -6.00
   GROUP BY ca.ca_state
   HAVING SUM(cs.cs_net_profit) > 1000
   UNION ALL
   SELECT ca.ca_state AS state,
          SUM(ss.ss_net_profit) AS total_profit,
          'Store' AS source
   FROM store_sales ss
   JOIN year_dates yd ON ss.ss_sold_date_sk = yd.d_date_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE ss.ss_ext_discount_amt < 100
   GROUP BY ca.ca_state
   HAVING SUM(ss.ss_net_profit) > 1000
) combined
ORDER BY total_profit DESC
LIMIT 100
