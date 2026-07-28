WITH filtered_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        i.i_brand AS i_brand,
        cd.cd_gender AS cd_gender,
        i.i_item_desc,
        i.i_product_name
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND i.i_product_name LIKE '%Premium%'
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.store_sales ss2
          JOIN tpcds.item i2 ON ss2.ss_item_sk = i2.i_item_sk
          WHERE ss2.ss_customer_sk = c.c_customer_sk
            AND i2.i_brand = 'BrandX'
      )
)
SELECT
    i_brand AS brand,
    cd_gender AS gender,
    CONCAT(i_brand, ' ', cd_gender) AS brand_gender_label,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss_ticket_number) AS order_count
FROM filtered_sales
GROUP BY ROLLUP (i_brand, cd_gender)
ORDER BY total_sales DESC
LIMIT 100
