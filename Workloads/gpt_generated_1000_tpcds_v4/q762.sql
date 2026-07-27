WITH joined AS (
    SELECT
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        sm.sm_code,
        td.t_hour,
        cr.cr_net_loss
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE
        regexp_like(sm.sm_code, '^A')
        AND cc.cc_name LIKE '%Center%'
        AND substring(cc.cc_city, 1, 1) = 'A'
)
SELECT
    cc_name,
    sm_code,
    t_hour,
    CONCAT(cc_city, '-', cc_state) AS location,
    regexp_extract(cc_name, '^([^ ]+)') AS first_word,
    SUM(cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt
FROM joined
GROUP BY
    cc_name,
    sm_code,
    t_hour,
    CONCAT(cc_city, '-', cc_state),
    regexp_extract(cc_name, '^([^ ]+)')
ORDER BY total_net_loss DESC
LIMIT 100
