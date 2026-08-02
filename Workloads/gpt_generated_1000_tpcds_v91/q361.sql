/*
Goal: Calculate monthly total net profit for catalog and web sales filtered by specific text patterns. For catalog sales, keep only rows where the catalog page description contains a three‑digit code and the page type starts with 'C', extracting the numeric code and concatenating it. For web sales, keep only rows where the web site manager name starts with 'J' and contains 'Ward', concatenating the manager name. Include the maximum income band upper bound as a scalar sub‑query value. Combine both result sets with UNION, order the final output, and limit to 100 rows.
*/
WITH date_filter AS (
    SELECT d_date_sk,
           d_year,
           d_month_seq
    FROM date_dim
    WHERE d_current_year = 'Y'
)
SELECT
    d.d_year AS year,
    d.d_month_seq AS month,
    'catalog' AS source,
    SUM(cs.cs_net_profit) AS total_profit,
    CONCAT('Desc-', REGEXP_EXTRACT(cp.cp_description, '(\\d+)', 1)) AS detail,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_band_upper
FROM catalog_sales cs
JOIN date_filter d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE REGEXP_LIKE(cp.cp_description, '\\d{3}')
  AND cp.cp_type LIKE 'C%'
GROUP BY
    d.d_year,
    d.d_month_seq,
    CONCAT('Desc-', REGEXP_EXTRACT(cp.cp_description, '(\\d+)', 1))
UNION
SELECT
    d.d_year AS year,
    d.d_month_seq AS month,
    'web' AS source,
    SUM(ws.ws_net_profit) AS total_profit,
    CONCAT('Mgr-', wsit.web_manager) AS detail,
    (SELECT MAX(ib_upper_bound) FROM income_band) AS max_income_band_upper
FROM web_sales ws
JOIN date_filter d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE wsit.web_manager LIKE '%Ward%'
  AND REGEXP_LIKE(wsit.web_manager, '^J')
GROUP BY
    d.d_year,
    d.d_month_seq,
    CONCAT('Mgr-', wsit.web_manager)
ORDER BY
    year DESC,
    month DESC,
    source ASC
LIMIT 100
