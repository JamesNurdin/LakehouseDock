/*
  Goal: Rank catalog and store sales per year for orders that meet several business criteria, showing the highest‑value orders and categorising them by sales amount.
*/
WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_coupon_amt,
        ca.ca_address_id,
        ca.ca_zip,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        d.d_year,
        wp.wp_web_page_id,
        wp.wp_type
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE cs.cs_coupon_amt > 100
      AND ca.ca_zip = '86192'
      AND d.d_year = 2001
      AND wp.wp_type = 'home'
),
preagg AS (
    SELECT
        cs_order_number,
        ca_address_id,
        d_year,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss_ext_sales_price) AS total_store_sales
    FROM joined
    GROUP BY cs_order_number, ca_address_id, d_year
)
SELECT
    cs_order_number,
    ca_address_id,
    d_year,
    total_catalog_sales,
    total_store_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_catalog_sales + total_store_sales) DESC) AS sales_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS catalog_sales_rownum,
    CASE WHEN total_catalog_sales > 5000 THEN 'High' ELSE 'Low' END AS sales_category
FROM preagg
ORDER BY d_year, sales_rank
LIMIT 100
