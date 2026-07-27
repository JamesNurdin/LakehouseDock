WITH filtered_stores AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_zip,
        s_city,
        s_state,
        -- extract the first two digits of the zip code
        regexp_extract(s_zip, '^([0-9]{2})', 1) AS zip_prefix,
        -- flag zip codes that contain the pattern "39"
        CASE WHEN regexp_like(s_zip, '39') THEN 1 ELSE 0 END AS zip_has_39,
        -- simple LIKE filter on zip codes starting with 4 or 39
        CASE WHEN s_zip LIKE '4%' THEN 1 ELSE 0 END AS zip_starts_4
    FROM store
    WHERE s_zip LIKE '39%' OR s_zip LIKE '4%'
),
sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        COUNT(*) AS txn_cnt
    FROM store_sales
    WHERE ss_ext_list_price > 5000
    GROUP BY ss_store_sk
)
SELECT
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS location,
    s.zip_prefix,
    a.total_sales,
    a.avg_profit,
    a.txn_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY a.total_sales DESC) AS rn_state
FROM filtered_stores AS s
JOIN sales_agg AS a
    ON a.ss_store_sk = s.s_store_sk
WHERE s.zip_has_39 = 1
ORDER BY a.total_sales DESC
LIMIT 100
