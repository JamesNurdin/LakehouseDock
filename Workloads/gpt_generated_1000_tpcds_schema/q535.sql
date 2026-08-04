(
  SELECT DISTINCT cs.cs_bill_customer_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND cs.cs_ext_discount_amt > 500
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_access_date_sk = d2.d_date_sk
        WHERE wp.wp_web_page_sk = cs.cs_catalog_page_sk
          AND wp.wp_image_count > 3
          AND d2.d_date_sk = cs.cs_ship_date_sk
    )
  UNION
  SELECT DISTINCT cs.cs_bill_customer_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND cs.cs_ext_discount_amt <= 500
    AND EXISTS (
        SELECT 1
        FROM web_page wp
        JOIN date_dim d2 ON wp.wp_access_date_sk = d2.d_date_sk
        WHERE wp.wp_web_page_sk = cs.cs_catalog_page_sk
          AND wp.wp_image_count > 3
          AND d2.d_date_sk = cs.cs_ship_date_sk
    )
) INTERSECT
SELECT DISTINCT cs.cs_bill_customer_sk
FROM catalog_sales cs
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 2
  AND cs.cs_net_paid_inc_tax > 1000
EXCEPT
SELECT DISTINCT cs.cs_bill_customer_sk
FROM catalog_sales cs
WHERE cs.cs_ext_list_price > 5000
LIMIT 100
