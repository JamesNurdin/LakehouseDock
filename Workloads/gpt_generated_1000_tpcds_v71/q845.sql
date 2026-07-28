SELECT product_name,
       gender,
       SUM(ext_sales_price) AS total_sales
FROM (
    SELECT DISTINCT
           i.i_product_name AS product_name,
           cd.cd_gender AS gender,
           ss.ss_ext_sales_price AS ext_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND i.i_current_price BETWEEN 30 AND 100
      AND EXISTS (
          SELECT 1 FROM store_sales ss2
          WHERE ss2.ss_customer_sk = ss.ss_customer_sk
            AND ss2.ss_quantity > 5
      )
    UNION ALL
    SELECT
           i.i_product_name,
           cd.cd_gender,
           ss.ss_ext_sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_promo_sk IS NULL
      AND i.i_current_price BETWEEN 30 AND 100
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
) t
GROUP BY product_name, gender
ORDER BY total_sales DESC
LIMIT 100
