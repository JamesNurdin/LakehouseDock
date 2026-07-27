WITH filtered_stores AS (
    SELECT
        s_store_sk,
        s_store_id,
        s_store_name,
        s_city,
        s_number_employees,
        s_closed_date_sk
    FROM store
    WHERE regexp_like(s_street_name, '\\d')
      AND s_city LIKE 'New%'
),
closed_store_dates AS (
    SELECT
        fs.s_store_sk,
        fs.s_store_id,
        fs.s_store_name,
        fs.s_city,
        fs.s_number_employees,
        fs.s_closed_date_sk,
        sd.d_date_sk
    FROM filtered_stores AS fs
    JOIN date_dim AS sd
        ON fs.s_closed_date_sk = sd.d_date_sk
    WHERE sd.d_weekend = 'Y'
)
SELECT
    ws.web_site_id,
    ws.web_name,
    COUNT(DISTINCT csd.s_store_sk) AS closed_store_cnt,
    AVG(csd.s_number_employees) AS avg_employees,
    CONCAT(ws.web_name, ' (', CAST(ws.web_mkt_id AS VARCHAR), ')') AS site_label
FROM web_site AS ws
JOIN date_dim AS od
    ON ws.web_open_date_sk = od.d_date_sk
JOIN closed_store_dates AS csd
    ON TRUE -- Cartesian join limited by filters above; purpose is to associate stores with each qualifying web site
WHERE od.d_year = 2001
GROUP BY ws.web_site_id, ws.web_name, ws.web_mkt_id
ORDER BY closed_store_cnt DESC
