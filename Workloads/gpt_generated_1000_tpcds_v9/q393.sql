WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        sr.sr_net_loss,
        s.s_city,
        s.s_state,
        s.s_store_name,
        s.s_zip,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(?i)(damage|defect)', 1) AS matched_reason
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|defect')
      AND (s.s_store_name LIKE 'A%' OR s.s_store_name LIKE '%Super%')
      AND s.s_zip LIKE '393%'
),
prepared AS (
    SELECT
        concat(fr.s_city, ', ', fr.s_state) AS location,
        fr.s_store_name,
        substring(fr.s_store_name, 1, 3) AS store_name_prefix,
        fr.matched_reason,
        CASE
            WHEN fr.hd_vehicle_count <= 0 THEN 'No vehicle'
            WHEN fr.hd_vehicle_count = 1 THEN 'One vehicle'
            ELSE 'Multiple vehicles'
        END AS vehicle_category,
        cast(fr.ib_lower_bound AS varchar) || '-' || cast(fr.ib_upper_bound AS varchar) AS income_range,
        fr.sr_net_loss
    FROM filtered_returns fr
)
SELECT
    p.location,
    p.store_name_prefix,
    p.matched_reason,
    p.vehicle_category,
    p.income_range,
    sum(p.sr_net_loss) AS total_net_loss,
    count(*) AS return_count
FROM prepared p
GROUP BY
    p.location,
    p.store_name_prefix,
    p.matched_reason,
    p.vehicle_category,
    p.income_range
ORDER BY total_net_loss DESC
LIMIT 100
