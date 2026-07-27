WITH catalog_sub AS (
    SELECT
        cc.cc_state AS state,
        sm.sm_carrier AS carrier,
        d1.d_year AS year,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
    WHERE
        cr.cr_return_quantity >= 10
        AND cr.cr_return_amount > 20
        AND d1.d_year BETWEEN 2000 AND 2002
        AND cc.cc_employees > 100
        AND sm.sm_carrier IN ('DHL', 'USPS')
        AND cc.cc_state IS NOT NULL
    GROUP BY GROUPING SETS (
        (cc.cc_state, sm.sm_carrier, d1.d_year),
        (cc.cc_state, sm.sm_carrier),
        (cc.cc_state, d1.d_year),
        (sm.sm_carrier, d1.d_year),
        ()
    )
),
store_sub AS (
    SELECT
        cc.cc_state AS state,
        'UNKNOWN' AS carrier,
        d2.d_year AS year,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        SUM(sr.sr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM store_returns sr
    JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d2.d_date_sk
    WHERE
        sr.sr_return_amt_inc_tax > 5
        AND sr.sr_return_quantity > 0
        AND d2.d_month_seq BETWEEN 1 AND 12
        AND cc.cc_gmt_offset BETWEEN -5 AND 5
        AND cc.cc_state IS NOT NULL
        AND d2.d_year BETWEEN 2000 AND 2002
    GROUP BY GROUPING SETS (
        (cc.cc_state, d2.d_year),
        (cc.cc_state),
        (d2.d_year),
        ()
    )
),
combined AS (
    SELECT * FROM catalog_sub
    UNION ALL
    SELECT * FROM store_sub
),
outer_agg AS (
    SELECT
        state,
        carrier,
        year,
        SUM(return_amount) AS total_return_amount,
        SUM(net_loss) AS total_net_loss,
        SUM(cnt) AS total_cnt,
        AVG(net_loss) AS avg_net_loss_per_return
    FROM combined
    GROUP BY GROUPING SETS (
        (state, carrier, year),
        (state, carrier),
        (state, year),
        (carrier, year),
        ()
    )
)
SELECT
    state,
    carrier,
    year,
    total_return_amount,
    total_net_loss,
    total_cnt,
    avg_net_loss_per_return
FROM outer_agg
ORDER BY
    CASE WHEN state IS NULL THEN 1 ELSE 0 END,
    state,
    carrier,
    year DESC
LIMIT 100
