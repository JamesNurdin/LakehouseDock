/* goal: Compare high‑value sales from catalog and store channels for a recent period, showing the customer, amount and channel */
WITH catalog_part AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cs.cs_ext_sales_price AS sale_amount,
        cs.cs_sold_date_sk AS sale_date_sk,
        'catalog' AS sale_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Electronics'
      AND cs.cs_sold_date_sk BETWEEN 2450820 AND 2450827
      AND cs.cs_ext_sales_price > 100
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_discount_active = 'Y'
      )
)
SELECT
    c_customer_id,
    customer_name,
    sale_amount,
    sale_date_sk,
    sale_channel
FROM catalog_part
UNION ALL
SELECT
    c2.c_customer_id,
    CONCAT(c2.c_first_name, ' ', c2.c_last_name) AS customer_name,
    ss.ss_ext_sales_price AS sale_amount,
    ss.ss_sold_date_sk AS sale_date_sk,
    'store' AS sale_channel
FROM tpcds.store_sales ss
JOIN tpcds.customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.item i2 ON ss.ss_item_sk = i2.i_item_sk
WHERE s.s_county = 'Williamson County'
  AND ss.ss_sold_date_sk BETWEEN 2450820 AND 2450827
  AND ss.ss_ext_sales_price > 100
  AND i2.i_brand IN (
      SELECT i3.i_brand
      FROM tpcds.item i3
      WHERE i3.i_category = 'Books'
  )
ORDER BY sale_amount DESC
LIMIT 100
