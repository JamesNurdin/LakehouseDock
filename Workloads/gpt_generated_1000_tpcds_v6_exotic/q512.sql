WITH sales_by_customer AS (
    SELECT
        c.c_customer_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        CASE
            WHEN SUM(cs.cs_ext_sales_price) > 2000 THEN 'High'
            WHEN SUM(cs.cs_ext_sales_price) > 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_tier
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cp.cp_catalog_page_number IN (5, 13, 15)
      AND sm.sm_contract = 'yVfotg7Tio3MVhBg6Bkn'
      AND p.p_discount_active = 'Y'
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )
    GROUP BY c.c_customer_id
)
SELECT
    c_customer_id,
    total_sales,
    sales_tier
FROM sales_by_customer
UNION ALL
SELECT
    c.c_customer_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > 2000 THEN 'High'
        WHEN SUM(cs.cs_ext_sales_price) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_tier
FROM catalog_sales cs
JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE cp.cp_catalog_page_number = 16
  AND sm.sm_code = 'AIR'
  AND p.p_discount_active = 'Y'
  AND NOT EXISTS (
      SELECT 1 FROM store_returns sr
      WHERE sr.sr_customer_sk = c.c_customer_sk
  )
GROUP BY c.c_customer_id
LIMIT 100
