SELECT DISTINCT
    cr.cr_returned_date_sk,
    cr.cr_order_number,
    cs.cs_sales_price,
    cr.cr_fee
FROM tpcds.catalog_returns AS cr
JOIN tpcds.catalog_sales AS cs
  ON cr.cr_order_number = cs.cs_order_number
WHERE cr.cr_fee > 30.32
  AND cs.cs_sales_price < 100.00
LIMIT 100
