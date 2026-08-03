WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        concat(cc.cc_state, '-', cc.cc_country) AS location_code,
        substring(cc.cc_city, 1, 3) AS city_prefix,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)', 1) AS first_word_reason
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cc.cc_name LIKE '%Center%'
      AND regexp_like(cc.cc_city, '^[A-Z]{3}')
      AND regexp_like(r.r_reason_desc, '(?i)damage')
      AND sm.sm_type = 'OVERNIGHT'
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_state,
        cc.cc_country,
        cc.cc_city,
        d.d_year,
        r.r_reason_desc
)
SELECT *
FROM (
    SELECT
        agg.*, 
        row_number() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rn
    FROM agg
) t
WHERE rn <= 5
LIMIT 100
