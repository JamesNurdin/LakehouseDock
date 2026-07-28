WITH customer_sales AS (
    SELECT
        c.c_customer_id,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid_inc_ship,
        COUNT(*) AS order_cnt,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450840 AND 2450900
      AND cs.cs_ext_ship_cost > 500
      AND cs.cs_net_paid_inc_ship < 20000
      AND c.c_birth_day IN (4, 17, 23)
      AND ca.ca_zip IN ('77752', '90419')
      AND c.c_last_review_date >= 2452400
      AND cp.cp_department = 'Electronics'
    GROUP BY c.c_customer_id
)
SELECT
    AVG(total_paid_inc_ship) AS avg_total_paid_inc_ship,
    SUM(order_cnt) AS total_orders,
    AVG(avg_ship_cost) AS avg_ship_cost_across_customers
FROM customer_sales
WHERE total_paid_inc_ship > 5000
HAVING COUNT(*) >= 10
