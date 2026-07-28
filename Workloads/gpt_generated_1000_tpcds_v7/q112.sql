-- Goal: Compute average net paid and total discount per demographic group (gender, marital status) for customers who have store sales, a US address, and visited a product web page, applying multiple filters.
WITH sales_by_customer AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cd.cd_dep_count > 0
      AND cd.cd_marital_status IN ('M', 'S')
      AND ss.ss_quantity > 10
      AND wp.wp_type = 'product'
      AND ca.ca_country = 'United States'
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    cd_gender,
    cd_marital_status,
    AVG(total_net_paid) AS avg_net_paid_per_customer,
    SUM(total_discount) AS sum_discount_all_customers,
    COUNT(*) AS num_customers
FROM sales_by_customer
GROUP BY cd_gender, cd_marital_status
HAVING AVG(total_net_paid) > 1000
ORDER BY avg_net_paid_per_customer DESC
LIMIT 100
