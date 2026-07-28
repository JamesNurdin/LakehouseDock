/* Goal: Identify customers with the highest total sales across store and catalog channels, excluding any customers who have an auto‑generated web page record. */
WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           c.c_email_address
    FROM tpcds.customer AS c
    WHERE NOT EXISTS (
        SELECT 1
        FROM tpcds.web_page AS wp
        WHERE wp.wp_customer_sk = c.c_customer_sk
          AND wp.wp_autogen_flag = 'Y'
    )
)
,
store_sales_agg AS (
    SELECT fc.c_customer_sk,
           fc.c_email_address,
           SUM(ss.ss_net_paid) AS total_sales,
           CAST('store' AS varchar) AS channel
    FROM filtered_customers AS fc
    JOIN tpcds.store_sales AS ss
        ON ss.ss_customer_sk = fc.c_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY fc.c_customer_sk, fc.c_email_address
)
,
catalog_sales_agg AS (
    SELECT fc.c_customer_sk,
           fc.c_email_address,
           SUM(cs.cs_net_paid) AS total_sales,
           CAST('catalog' AS varchar) AS channel
    FROM filtered_customers AS fc
    JOIN tpcds.catalog_sales AS cs
        ON cs.cs_bill_customer_sk = fc.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2455000
    GROUP BY fc.c_customer_sk, fc.c_email_address
)
SELECT ca.c_customer_sk,
       ca.c_email_address,
       ca.total_sales,
       ca.channel
FROM store_sales_agg AS ca
UNION ALL
SELECT ca.c_customer_sk,
       ca.c_email_address,
       ca.total_sales,
       ca.channel
FROM catalog_sales_agg AS ca
ORDER BY total_sales DESC
LIMIT 100
