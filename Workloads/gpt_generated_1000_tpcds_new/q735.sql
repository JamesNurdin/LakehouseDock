WITH sales_q AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_ext_sales_price AS amount,
        'SALE' AS txn_type,
        s.s_store_name AS store_name,
        i.i_category AS category,
        i.i_product_name AS product_name,
        i.i_item_desc AS item_desc
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'TX'
      AND REGEXP_LIKE(i.i_item_desc, '[0-9]{3}')
      AND i.i_item_desc LIKE '%BRAND%'
),
returns_q AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_amt AS amount,
        'RETURN' AS txn_type,
        s2.s_store_name AS store_name,
        i2.i_category AS category,
        i2.i_product_name AS product_name,
        i2.i_item_desc AS item_desc
    FROM store_returns sr
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    WHERE s2.s_state = 'TX'
      AND sr.sr_return_amt > 0
      AND REGEXP_LIKE(i2.i_item_desc, '[0-9]{3}')
      AND i2.i_item_desc LIKE '%BRAND%'
),
union_set AS (
    SELECT * FROM sales_q
    UNION
    SELECT * FROM returns_q
),
intersect_items AS (
    SELECT item_sk FROM union_set
    INTERSECT
    SELECT inv.inv_item_sk
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city = 'Seattle'
),
filtered AS (
    SELECT u.*
    FROM union_set u
    JOIN intersect_items i ON u.item_sk = i.item_sk
)
SELECT
    f.store_name,
    f.category,
    CONCAT(f.store_name, '-', f.category) AS store_category_key,
    SUM(CASE WHEN f.txn_type = 'SALE' THEN f.amount ELSE 0 END) AS total_sales,
    SUM(CASE WHEN f.txn_type = 'RETURN' THEN f.amount ELSE 0 END) AS total_returns,
    CASE WHEN SUM(CASE WHEN f.txn_type = 'SALE' THEN f.amount ELSE 0 END) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_level,
    l.product_prefix,
    l.numeric_part
FROM filtered f
CROSS JOIN LATERAL (
    SELECT
        SUBSTRING(f.product_name FROM 1 FOR 10) AS product_prefix,
        REGEXP_EXTRACT(f.product_name, '(\\d+)', 1) AS numeric_part
) AS l
GROUP BY
    f.store_name,
    f.category,
    l.product_prefix,
    l.numeric_part
ORDER BY total_sales DESC
LIMIT 100
