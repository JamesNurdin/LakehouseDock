WITH united AS (
    SELECT
        c.c_customer_id,
        i.i_category,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
        CASE WHEN COALESCE(SUM(cr.cr_return_amount), 0) > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
        REGEXP_EXTRACT(i.i_item_desc, '(large|small|medium)') AS size_match
    FROM store_sales ss
    FULL OUTER JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
    JOIN item i
        ON COALESCE(ss.ss_item_sk, cr.cr_item_sk) = i.i_item_sk
    JOIN customer c
        ON COALESCE(ss.ss_customer_sk, cr.cr_refunded_customer_sk) = c.c_customer_sk
    WHERE i.i_item_desc LIKE '%large%'
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_customer_sk = c.c_customer_sk
            AND ss2.ss_ext_sales_price > 200
      )
    GROUP BY c.c_customer_id, i.i_category, i.i_item_desc

    UNION DISTINCT

    SELECT
        c.c_customer_id,
        i.i_category,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
        CASE WHEN COALESCE(SUM(cr.cr_return_amount), 0) > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag,
        REGEXP_EXTRACT(i.i_item_desc, '(large|small|medium)') AS size_match
    FROM store_sales ss
    FULL OUTER JOIN catalog_returns cr
        ON ss.ss_item_sk = cr.cr_item_sk
    JOIN item i
        ON COALESCE(ss.ss_item_sk, cr.cr_item_sk) = i.i_item_sk
    JOIN customer c
        ON COALESCE(ss.ss_customer_sk, cr.cr_refunded_customer_sk) = c.c_customer_sk
    WHERE i.i_item_desc LIKE '%small%'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr2
          WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
            AND cr2.cr_return_amount > 0
      )
    GROUP BY c.c_customer_id, i.i_category, i.i_item_desc
)
SELECT
    CONCAT(c_customer_id, '-', i_category) AS cust_cat,
    total_sales,
    total_returns,
    return_flag,
    size_match
FROM united
ORDER BY total_returns DESC
LIMIT 100
