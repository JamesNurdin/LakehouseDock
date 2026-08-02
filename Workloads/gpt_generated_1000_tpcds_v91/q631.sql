WITH sales_agg AS (
    SELECT 
        ws.ws_web_site_sk AS ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    WHERE ws.ws_ext_tax > 5
    GROUP BY ws.ws_web_site_sk
)
SELECT 
    s.ws_web_site_sk,
    w.web_site_id,
    s.total_net_paid,
    s.avg_net_profit,
    s.order_cnt,
    l.name_category,
    l.street_word,
    l.full_address,
    l.zip_group
FROM sales_agg s
JOIN web_site w
    ON s.ws_web_site_sk = w.web_site_sk
CROSS JOIN LATERAL (
    SELECT 
        CASE WHEN regexp_like(w.web_name, '(?i)store') THEN 'Store' ELSE 'Other' END AS name_category,
        regexp_extract(w.web_street_name, '([A-Za-z]+)', 1) AS street_word,
        concat(w.web_street_number, ' ', w.web_street_name) AS full_address,
        CASE WHEN w.web_zip LIKE '48%' THEN 'ZIP_48_PREFIX' ELSE 'OTHER_ZIP' END AS zip_group
) AS l
WHERE l.name_category = 'Store'
ORDER BY s.total_net_paid DESC
LIMIT 100
