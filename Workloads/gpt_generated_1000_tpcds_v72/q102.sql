SELECT DISTINCT
    c.c_customer_id,
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship,
    cs.cs_ext_tax
FROM tpcds.catalog_sales cs
JOIN tpcds.customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE cs.cs_ext_tax > 20.00
  AND c.c_current_cdemo_sk = 93662
ORDER BY cs.cs_net_paid_inc_ship DESC
LIMIT 100
