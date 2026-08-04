WITH ss AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name
),
ws AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_net_paid) AS total_web_sales
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_item_desc,
        i.i_product_name
)
SELECT
    i_brand,
    i_item_id,
    i_item_desc,
    SUM(COALESCE(total_store_qty, 0)) AS sum_store_qty,
    SUM(COALESCE(total_store_sales, 0)) AS sum_store_sales,
    SUM(COALESCE(total_web_qty, 0)) AS sum_web_qty,
    SUM(COALESCE(total_web_sales, 0)) AS sum_web_sales,
    regexp_extract(i_item_id, '(\\d+)', 1) AS numeric_part,
    CASE
        WHEN regexp_like(i_item_desc, '(?i)eco|economy') THEN 'Eco'
        ELSE 'Other'
    END AS desc_category
FROM (
    SELECT *
    FROM ss
    FULL OUTER JOIN ws USING (i_item_sk, i_item_id, i_brand, i_item_desc, i_product_name)
) t
GROUP BY GROUPING SETS (
    (i_brand, i_item_id, i_item_desc),
    (i_brand),
    (i_item_id),
    ()
)
ORDER BY sum_store_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
