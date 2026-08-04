/*
Goal: Identify the top 100 store‑item combinations in 2001 where the item description mentions "small" or "large" and the item color starts with "B", ensuring the item has never been returned for that store on the same sale date. The query demonstrates string processing (REGEXP_LIKE, REGEXP_EXTRACT, LIKE), uses a CROSS JOIN with a small derived dimension, applies an anti‑join via NOT EXISTS, removes items that have any returns using EXCEPT, includes DISTINCT, performs aggregation, orders by total sales and limits the result.
*/
WITH sold_items AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_color,
        i.i_size,
        s.s_store_name,
        d.d_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '(small|large)')
      AND i.i_color LIKE 'B%'
),
items_without_return AS (
    SELECT ss_item_sk FROM store_sales
    EXCEPT
    SELECT sr_item_sk FROM store_returns
),
cross_dim AS (
    SELECT d.d_date_sk, v.flag
    FROM (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 5
    ) d
    CROSS JOIN (VALUES 'X'), (VALUES 'Y') AS v(flag)
)
SELECT DISTINCT
    concat(st.s_store_name, ' - ', i.i_item_id, ' - ', cd.flag) AS store_item_flag,
    i.i_item_id,
    i.i_product_name,
    st.s_store_name,
    d2.d_year,
    regexp_extract(i.i_item_desc, '(small|large)', 1) AS size_match,
    sum(si.ss_quantity) AS total_quantity,
    sum(si.ss_net_paid) AS total_sales
FROM sold_items si
JOIN items_without_return ir ON si.ss_item_sk = ir.ss_item_sk
JOIN cross_dim cd ON si.ss_sold_date_sk = cd.d_date_sk
JOIN item i ON si.ss_item_sk = i.i_item_sk
JOIN store st ON si.ss_store_sk = st.s_store_sk
JOIN date_dim d2 ON si.ss_sold_date_sk = d2.d_date_sk
WHERE NOT EXISTS (
    SELECT 1 FROM store_returns sr
    WHERE sr.sr_item_sk = si.ss_item_sk
      AND sr.sr_store_sk = si.ss_store_sk
      AND sr.sr_returned_date_sk = si.ss_sold_date_sk
)
GROUP BY
    concat(st.s_store_name, ' - ', i.i_item_id, ' - ', cd.flag),
    i.i_item_id,
    i.i_product_name,
    st.s_store_name,
    d2.d_year,
    regexp_extract(i.i_item_desc, '(small|large)', 1)
ORDER BY total_sales DESC
LIMIT 100
