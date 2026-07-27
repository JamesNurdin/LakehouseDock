WITH filtered_dates AS (
    SELECT d_date_sk, d_fy_quarter_seq
    FROM date_dim
    WHERE d_fy_quarter_seq IN (7, 8)
)
SELECT DISTINCT q.item_sk,
                q.product_name,
                q.quarter,
                q.total_sales
FROM (
    SELECT i.i_item_sk AS item_sk,
           i.i_product_name AS product_name,
           fd.d_fy_quarter_seq AS quarter,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_units = 'Ton'
      AND fd.d_fy_quarter_seq = 7
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = i.i_item_sk
            AND ss2.ss_coupon_amt > 500
      )
    GROUP BY i.i_item_sk, i.i_product_name, fd.d_fy_quarter_seq
    HAVING SUM(ss.ss_ext_sales_price) > (
        SELECT AVG(ss3.ss_ext_sales_price)
        FROM store_sales ss3
        WHERE ss3.ss_item_sk = i.i_item_sk
    )

    UNION ALL

    SELECT i.i_item_sk AS item_sk,
           i.i_product_name AS product_name,
           fd.d_fy_quarter_seq AS quarter,
           SUM(ss.ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN filtered_dates fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_units = 'Lb'
      AND fd.d_fy_quarter_seq = 8
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_item_sk = i.i_item_sk
            AND ss2.ss_coupon_amt > 500
      )
    GROUP BY i.i_item_sk, i.i_product_name, fd.d_fy_quarter_seq
    HAVING SUM(ss.ss_ext_sales_price) > (
        SELECT AVG(ss3.ss_ext_sales_price)
        FROM store_sales ss3
        WHERE ss3.ss_item_sk = i.i_item_sk
    )
) AS q
LIMIT 100
