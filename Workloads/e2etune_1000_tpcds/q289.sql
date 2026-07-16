WITH cc_agg AS (
    SELECT 
        cc_state,
        COUNT(*) AS cc_count,
        SUM(cc_employees) AS total_employees,
        AVG(cc_sq_ft) AS avg_sq_ft,
        AVG(cc_tax_percentage) AS avg_cc_tax
    FROM call_center
    WHERE cc_rec_end_date >= DATE '2000-01-01'
    GROUP BY cc_state
    HAVING COUNT(*) >= 3
),
ws_agg AS (
    SELECT 
        web_state,
        COUNT(*) AS ws_count,
        AVG(web_tax_percentage) AS avg_ws_tax,
        AVG(web_gmt_offset) AS avg_gmt_offset
    FROM web_site
    WHERE web_open_date_sk IS NOT NULL
    GROUP BY web_state
)
SELECT
    cc.cc_state AS state,
    cc.cc_count,
    ws.ws_count,
    cc.total_employees,
    cc.avg_sq_ft,
    cc.avg_cc_tax,
    ws.avg_ws_tax,
    ws.avg_gmt_offset,
    CASE WHEN ws.ws_count = 0 THEN NULL ELSE cc.total_employees * 1.0 / ws.ws_count END AS employees_per_website,
    RANK() OVER (ORDER BY CASE WHEN ws.ws_count = 0 THEN 0 ELSE cc.total_employees * 1.0 / ws.ws_count END DESC) AS state_rank
FROM cc_agg cc
JOIN ws_agg ws
    ON cc.cc_state = ws.web_state
WHERE cc.avg_cc_tax > 0.05
ORDER BY employees_per_website DESC
LIMIT 20
