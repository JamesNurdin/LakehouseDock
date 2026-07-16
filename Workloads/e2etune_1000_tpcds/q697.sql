WITH dept_state_sales AS (
    SELECT
        cp.cp_department,
        ca.ca_state,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450900 AND 2451100
      AND c.c_preferred_cust_flag = 'Y'
      AND cp.cp_department IS NOT NULL
    GROUP BY cp.cp_department, ca.ca_state
)
SELECT
    cp_department,
    ca_state,
    total_net_profit,
    total_sales,
    avg_discount,
    sales_cnt,
    distinct_customers,
    total_net_profit / NULLIF(total_sales, 0) AS profit_margin
FROM dept_state_sales
WHERE total_net_profit > 10000
ORDER BY total_net_profit DESC
LIMIT 10
