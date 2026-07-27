SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_ship_date_sk = 2450864
  AND cs.cs_ship_cdemo_sk = 23666
LIMIT 100
