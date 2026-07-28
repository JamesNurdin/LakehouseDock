WITH recent_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity >= 2                       -- at least two items per return
        AND cr.cr_return_amount >= 150.00                    -- sizable return amount
        AND cr.cr_returned_date_sk BETWEEN 2450995 AND 2451085   -- recent return dates
        AND cr.cr_fee < 20.00                                 -- low processing fee
        AND cr.cr_return_ship_cost <= 30.00                  -- modest shipping cost
)
SELECT
    cc.cc_name,
    cp.cp_department,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.t_meal_time,
    COUNT(*) AS returns_cnt,
    SUM(rr.cr_return_amount) AS total_return_amount,
    AVG(rr.cr_net_loss) AS avg_net_loss,
    MIN(rr.cr_return_amount) AS min_return_amount,
    MAX(rr.cr_return_amount) AS max_return_amount
FROM recent_returns rr
JOIN call_center cc
    ON rr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON rr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
    ON rr.cr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ref
    ON rr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON rr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
WHERE EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = rr.cr_reason_sk
          AND r.r_reason_desc = 'Damaged'
    )
    AND cp.cp_catalog_page_number IN (2, 7, 14, 21)            -- specific catalog pages
    AND t.t_meal_time = 'dinner'                               -- returns occurring at dinner time
    AND cc.cc_state = 'CA'                                      -- California call centres
    AND cc.cc_gmt_offset BETWEEN -8.00 AND -5.00               -- West Coast time zones
GROUP BY
    cc.cc_name,
    cp.cp_department,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.t_meal_time
HAVING SUM(rr.cr_return_amount) > 10000                         -- only high‑value groups
ORDER BY total_return_amount DESC
LIMIT 50
