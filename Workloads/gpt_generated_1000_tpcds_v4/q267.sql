WITH sales_data AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_cdemo_sk,
       ss.ss_addr_sk,
       ss.ss_net_paid,
       ss.ss_coupon_amt,
       ss.ss_quantity,
       ss.ss_sales_price,
       d.d_year,
       d.d_month_seq,
       i.i_brand,
       i.i_category,
       ca.ca_state,
       ca.ca_zip,
       cd.cd_gender,
       cd.cd_dep_count,
       cc.cc_name,
       cp.cp_type
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND ca.ca_state = 'CA'
     AND ss.ss_coupon_amt > 1000
     AND cd.cd_dep_count <= 2
)
SELECT
    s.d_year,
    s.i_brand,
    s.ca_state,
    s.cd_gender,
    s.cc_name,
    CASE WHEN s.ss_coupon_amt > 5000 THEN 'High' ELSE 'Low' END AS coupon_category,
    COUNT(*) AS transaction_count,
    SUM(s.ss_net_paid) AS total_net_paid,
    AVG(s.ss_quantity) AS avg_quantity,
    MIN(s.ss_sales_price) AS min_sales_price,
    MAX(s.ss_sales_price) AS max_sales_price
FROM sales_data s
GROUP BY
    s.d_year,
    s.i_brand,
    s.ca_state,
    s.cd_gender,
    s.cc_name,
    CASE WHEN s.ss_coupon_amt > 5000 THEN 'High' ELSE 'Low' END
ORDER BY total_net_paid DESC
LIMIT 100
