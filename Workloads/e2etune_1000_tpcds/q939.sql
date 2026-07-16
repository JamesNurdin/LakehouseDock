WITH band_reason AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        COUNT(*) AS band_reason_cnt
    FROM income_band ib
    JOIN reason r
        ON r.r_reason_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound >= 20000
      AND r.r_reason_desc LIKE '%product%'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, r.r_reason_desc
),
ship_stats AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_type,
        COUNT(*) AS ship_cnt
    FROM ship_mode sm
    WHERE sm.sm_type IN ('AIR', 'GROUND')
    GROUP BY sm.sm_ship_mode_sk, sm.sm_carrier, sm.sm_type
),
web_stats AS (
    SELECT
        ws.web_state,
        ws.web_country,
        COUNT(*) AS site_cnt,
        AVG(ws.web_gmt_offset) AS avg_gmt_offset
    FROM web_site ws
    WHERE ws.web_open_date_sk >= 20000101
    GROUP BY ws.web_state, ws.web_country
)
SELECT
    br.ib_income_band_sk,
    br.r_reason_desc,
    br.band_reason_cnt,
    ss.sm_carrier,
    ss.ship_cnt,
    ws.web_state,
    ws.site_cnt,
    ROW_NUMBER() OVER (PARTITION BY br.ib_income_band_sk ORDER BY ss.ship_cnt DESC) AS ship_rank,
    RANK() OVER (ORDER BY br.band_reason_cnt DESC) AS global_reason_rank
FROM band_reason br
JOIN ship_stats ss
    ON br.ib_income_band_sk = ss.sm_ship_mode_sk
JOIN web_stats ws
    ON ws.web_state = CASE WHEN ss.sm_type = 'AIR' THEN 'CA' ELSE 'NY' END
WHERE br.band_reason_cnt > 5
ORDER BY br.band_reason_cnt DESC, ss.ship_cnt DESC
LIMIT 100
