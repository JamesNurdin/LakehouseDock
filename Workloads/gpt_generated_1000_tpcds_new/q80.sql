WITH cc_expanded AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            cc.cc_state,
            split(cc.cc_hours, ',') AS hours_arr
        FROM call_center cc
        WHERE cc.cc_state = 'CA' -- filter predicate 1
    ),
    cc_hours AS (
        SELECT
            cc_call_center_sk,
            cc_name,
            cc_state,
            hour
        FROM cc_expanded
        CROSS JOIN UNNEST(hours_arr) AS t(hour)
    )
SELECT
    sr.sr_ticket_number,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    s.s_store_name,
    r.r_reason_desc,
    sr.sr_return_amt,
    cr.cr_return_amount,
    cc_hours.cc_name AS call_center_name,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sr.sr_return_amt DESC) AS store_return_rank,
    DENSE_RANK() OVER (ORDER BY sr.sr_return_amt DESC) AS overall_return_rank
FROM store_returns sr
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
    AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN cc_hours ON cc.cc_call_center_sk = cc_hours.cc_call_center_sk
WHERE
    s.s_state = 'CA'                                 -- filter predicate 2
    AND c.c_birth_year BETWEEN 1970 AND 1990         -- filter predicate 3
    AND hd.hd_vehicle_count > 1                      -- filter predicate 4
    AND r.r_reason_desc LIKE '%order%'               -- filter predicate 5
    AND cr.cr_return_amount > 100                    -- filter predicate 6
ORDER BY sr.sr_return_amt DESC
LIMIT 100
