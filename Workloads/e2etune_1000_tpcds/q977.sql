SELECT
    cc.cc_name AS call_center_name,
    cc.cc_division_name,
    cc.cc_state,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    SUM(cs.cs_quantity) AS total_quantity
FROM
    catalog_sales cs
JOIN
    call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
    cc.cc_zip IN ('38828', '74136')
    AND cs.cs_ext_discount_amt > 10.0
    AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
GROUP BY
    cc.cc_name,
    cc.cc_division_name,
    cc.cc_state
HAVING
    SUM(cs.cs_net_profit) > 0
ORDER BY
    total_net_profit DESC
LIMIT 100
