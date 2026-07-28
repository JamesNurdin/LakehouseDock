WITH filtered_inventory AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        i.inv_date_sk,
        d.d_date,
        d.d_day_name,
        d.d_date_id
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_warehouse_sk = 11
      AND regexp_like(d.d_day_name, '^M.*')
)
SELECT
    cc.cc_state,
    substr(cc.cc_name, 1, 10) AS cc_name_prefix,
    CASE
        WHEN regexp_like(cc.cc_manager, '^A.*') THEN 'A_Manager'
        ELSE 'Other_Manager'
    END AS manager_category,
    ws.web_class,
    SUM(fi.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT fi.d_date) AS distinct_days,
    concat(ws.web_name, ' - ', ws.web_city) AS site_full_name
FROM filtered_inventory fi
JOIN call_center cc ON cc.cc_open_date_sk = fi.inv_date_sk
JOIN web_site ws ON ws.web_open_date_sk = fi.inv_date_sk
WHERE cc.cc_city LIKE '%York%'
  AND ws.web_name LIKE '%Online%'
GROUP BY
    cc.cc_state,
    substr(cc.cc_name, 1, 10),
    CASE
        WHEN regexp_like(cc.cc_manager, '^A.*') THEN 'A_Manager'
        ELSE 'Other_Manager'
    END,
    ws.web_class,
    concat(ws.web_name, ' - ', ws.web_city)
ORDER BY total_qty DESC
LIMIT 100
