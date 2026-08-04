WITH catalog_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        i.i_category,
        i.i_product_name,
        cs.cs_net_paid,
        d.d_year,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS full_name,
        REGEXP_EXTRACT(i.i_product_name, '(\\d{4})', 1) AS extracted_code
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND REGEXP_LIKE(i.i_product_name, '(?i)\\b[A-Z]{2}\\d{2}\\b')
      AND i.i_current_price > (SELECT AVG(i_current_price) FROM item)
),
store_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        i.i_category,
        i.i_product_name,
        d.d_year,
        CONCAT(i.i_brand, ' ', i.i_product_name) AS full_name,
        REGEXP_EXTRACT(i.i_product_name, '(\\d{4})', 1) AS extracted_code
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_product_name LIKE '%discount%'
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr
          WHERE cr.cr_item_sk = ss.ss_item_sk
      )
)
SELECT
    cat,
    total_sales,
    order_cnt,
    rnk
FROM (
    SELECT
        cd.i_category AS cat,
        SUM(cd.cs_net_paid) AS total_sales,
        COUNT(DISTINCT cd.cs_order_number) AS order_cnt,
        ROW_NUMBER() OVER (PARTITION BY cd.i_category ORDER BY SUM(cd.cs_net_paid) DESC) AS rnk
    FROM catalog_data cd
    WHERE NOT EXISTS (
        SELECT 1 FROM catalog_returns cr
        WHERE cr.cr_order_number = cd.cs_order_number
    )
    GROUP BY cd.i_category

    UNION

    SELECT
        sd.i_category AS cat,
        SUM(sd.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        ROW_NUMBER() OVER (PARTITION BY sd.i_category ORDER BY SUM(sd.ss_ext_sales_price) DESC) AS rnk
    FROM store_data sd
    GROUP BY sd.i_category
) t
ORDER BY total_sales DESC
LIMIT 100
