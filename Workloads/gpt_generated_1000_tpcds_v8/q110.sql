WITH store_sales_2022 AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT
    u.item_id,
    u.total_sales,
    u.source,
    CASE WHEN u.total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    (
        SELECT COUNT(DISTINCT cs2.cs_bill_customer_sk)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = u.item_sk
          AND cs2.cs_sold_date_sk = (
                SELECT d3.d_date_sk
                FROM date_dim d3
                WHERE d3.d_year = 2022
                ORDER BY d3.d_date_sk DESC
                LIMIT 1
          )
    ) AS recent_customer_cnt
FROM (
    SELECT
        ss.item_sk,
        ss.item_id,
        ss.total_sales,
        'store' AS source
    FROM store_sales_2022 ss

    UNION ALL

    SELECT
        cs.cs_item_sk AS item_sk,
        i.i_item_id AS item_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY cs.cs_item_sk, i.i_item_id
) AS u
ORDER BY u.total_sales DESC
LIMIT 100
