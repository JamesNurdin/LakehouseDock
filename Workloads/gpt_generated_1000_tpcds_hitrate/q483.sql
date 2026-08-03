SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cu.c_first_name,
    cu.c_last_name
FROM
    tpcds.catalog_sales cs
JOIN
    tpcds.customer cu
    ON cs.cs_bill_customer_sk = cu.c_customer_sk
WHERE
    cs.cs_coupon_amt > 300
    AND cu.c_current_cdemo_sk = 965059
LIMIT 100
