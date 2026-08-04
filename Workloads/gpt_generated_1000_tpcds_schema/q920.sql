WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
inv_wh AS (
    SELECT 
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_name,
        w.w_city,
        w.w_warehouse_sq_ft
    FROM sampled_inventory i
    FULL OUTER JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
),
reason_words AS (
    SELECT r.r_reason_sk, word
    FROM reason r
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(word)
),
pages_not_in_inv AS (
    SELECT cp.cp_catalog_page_sk
    FROM catalog_page cp
    EXCEPT
    SELECT inv.inv_warehouse_sk
    FROM inventory inv
)
SELECT
    iw.w_city,
    COUNT(DISTINCT iw.inv_warehouse_sk) AS warehouse_cnt,
    SUM(COALESCE(iw.inv_quantity_on_hand, 0)) AS total_quantity,
    COUNT(DISTINCT rw.r_reason_sk) AS distinct_reason_cnt,
    (SELECT COUNT(*) FROM pages_not_in_inv) AS pages_not_in_inventory_cnt,
    regexp_extract(iw.w_city, '(\\w+)$') AS city_suffix,
    CONCAT(iw.w_warehouse_name, ' (', CAST(iw.w_warehouse_sq_ft AS VARCHAR), ' sqft)') AS warehouse_desc
FROM inv_wh iw
LEFT JOIN reason_words rw
    ON regexp_like(rw.word, '^.*[aA]ction.*$')
WHERE iw.w_warehouse_name LIKE '%Warehouse%'
  AND regexp_like(iw.w_city, '\\d{5}$') = false
GROUP BY
    iw.w_city,
    regexp_extract(iw.w_city, '(\\w+)$'),
    CONCAT(iw.w_warehouse_name, ' (', CAST(iw.w_warehouse_sq_ft AS VARCHAR), ' sqft)')
ORDER BY total_quantity DESC
LIMIT 100
