WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_ext_sales_price > 0
)
SELECT
    cc.cc_name,
    cp.cp_type,
    d.d_year,
    SUM(fs.cs_ext_sales_price) AS total_sales,
    AVG(fs.cs_ext_discount_amt) AS avg_discount,
    COUNT(*) AS order_cnt,
    CASE WHEN SUM(fs.cs_ext_sales_price) > 50000 THEN 'High' ELSE 'Low' END AS sales_category
FROM filtered_sales fs
JOIN date_dim d
    ON fs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc
    ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_address ca_bill
    ON fs.cs_bill_addr_sk = ca_bill.ca_address_sk
WHERE d.d_year = 2001
  AND cc.cc_state = 'CA'
  AND ca_bill.ca_state = 'CA'
  AND cp.cp_type IN ('monthly', 'quarterly')
  AND cc.cc_street_name = 'Sycamore'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca_ship
        WHERE ca_ship.ca_address_sk = fs.cs_ship_addr_sk
          AND ca_ship.ca_zip LIKE '9%'
    )
GROUP BY cc.cc_name, cp.cp_type, d.d_year
ORDER BY total_sales DESC
LIMIT 100
