WITH max_high_wholesale AS (
    SELECT MAX(cs_sub.cs_net_paid) AS max_net_paid
    FROM catalog_sales cs_sub
    WHERE cs_sub.cs_wholesale_cost > 50.00
)
SELECT
    cc.cc_city,
    cu.c_birth_year,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_tax) AS avg_ext_tax,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_paid ELSE 0 END) AS profit_net_paid,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid,
    CASE WHEN SUM(cs.cs_net_paid) > (SELECT max_net_paid FROM max_high_wholesale) THEN 'Above Max' ELSE 'Below Max' END AS net_paid_vs_max
FROM catalog_sales cs
JOIN customer cu
    ON cs.cs_bill_customer_sk = cu.c_customer_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
WHERE
    cs.cs_ext_tax > 20.00
    AND cs.cs_wholesale_cost BETWEEN 30.00 AND 80.00
    AND cs.cs_net_paid < 5000.00
    AND cc.cc_city = 'Mount Pleasant'
    AND cu.c_birth_year = 1985
    AND cr.cr_return_amount > 0.00
GROUP BY
    cc.cc_city,
    cu.c_birth_year
ORDER BY
    total_net_paid DESC
LIMIT 100
