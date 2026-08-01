WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2001
    )
)
SELECT
    sm.sm_ship_mode_id,
    sm.sm_type,
    COUNT(DISTINCT ss.cs_item_sk) AS distinct_items_sold,
    SUM(ss.cs_net_paid) AS total_net_paid,
    COUNT(DISTINCT s.s_store_id) AS distinct_stores,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    CASE
        WHEN regexp_like(s.s_store_name, '^A.*') THEN 'StartsWithA'
        ELSE 'Other'
    END AS store_name_category,
    regexp_extract(ws.web_name, '(\\w+)\\s+Site', 1) AS extracted_site_word,
    substr(dd.d_day_name, 1, 3) AS day_name_abbr
FROM sampled_sales ss
JOIN date_dim dd
    ON ss.cs_sold_date_sk = dd.d_date_sk
JOIN ship_mode sm
    ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
    ON s.s_closed_date_sk = dd.d_date_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = dd.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_order_number = ss.cs_order_number
      AND cr.cr_item_sk = ss.cs_item_sk
)
  AND s.s_store_name LIKE '%Store%'
  AND ws.web_name LIKE '%Online%'
GROUP BY
    sm.sm_ship_mode_id,
    sm.sm_type,
    s.s_city,
    s.s_state,
    CASE
        WHEN regexp_like(s.s_store_name, '^A.*') THEN 'StartsWithA'
        ELSE 'Other'
    END,
    regexp_extract(ws.web_name, '(\\w+)\\s+Site', 1),
    substr(dd.d_day_name, 1, 3)
ORDER BY total_net_paid DESC
OFFSET 0 LIMIT 100
