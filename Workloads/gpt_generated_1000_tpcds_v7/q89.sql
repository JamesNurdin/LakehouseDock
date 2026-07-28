WITH sales_joined AS (
    SELECT
        cc.cc_name,
        cust.c_first_name,
        cust.c_last_name,
        ca.ca_suite_number,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN customer cust
        ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        REGEXP_LIKE(ca.ca_suite_number, '^Suite [A-Z]$')
        AND w.w_city LIKE 'O%'
) 
SELECT
    cc_name,
    CONCAT(c_first_name, ' ', c_last_name) AS customer_name,
    REGEXP_EXTRACT(ca_suite_number, '\\d+') AS suite_number_digits,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS order_count,
    AVG(cs_quantity) AS avg_quantity
FROM sales_joined
GROUP BY
    cc_name,
    CONCAT(c_first_name, ' ', c_last_name),
    REGEXP_EXTRACT(ca_suite_number, '\\d+')
ORDER BY total_profit DESC
LIMIT 100
