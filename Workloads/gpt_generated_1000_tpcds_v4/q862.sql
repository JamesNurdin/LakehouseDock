SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_product_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(cs.cs_ext_sales_price) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(cs.cs_ext_sales_price) - COALESCE(SUM(sr.sr_return_amt), 0) DESC) AS sales_rank
FROM catalog_sales cs
INNER JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
INNER JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
LEFT JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
  AND sr.sr_item_sk = i.i_item_sk
WHERE regexp_like(i.i_item_desc, '\\d{3}')
  AND i.i_category LIKE 'Electronics%'
  AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND substring(i.i_product_name, 1, 10) = 'SpecialPro'
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, i.i_product_name, c.c_customer_sk
ORDER BY net_sales DESC
LIMIT 100
