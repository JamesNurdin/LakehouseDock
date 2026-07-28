WITH returns_a AS (
    SELECT
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_ticket_number
    FROM tpcds.store_returns sr
    INNER JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 80000
      AND r.r_reason_desc = 'duplicate purchase'
      AND sr.sr_return_amt > 100.00
      AND hd.hd_buy_potential = 'high'
),
returns_b AS (
    SELECT
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        r.r_reason_desc,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_ticket_number
    FROM tpcds.store_returns sr
    INNER JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    INNER JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    INNER JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_vehicle_count >= 2
      AND sr.sr_return_ship_cost > 0.00
      AND hd.hd_dep_count = 1
      AND r.r_reason_id LIKE 'AAAAAAA%'
)
SELECT
    ib_upper_bound,
    MIN(ib_lower_bound) AS income_lower,
    r_reason_desc,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_quantity) AS avg_return_qty,
    COUNT(*) AS return_cnt,
    GROUPING(ib_upper_bound) AS grp_income,
    GROUPING(r_reason_desc) AS grp_reason
FROM (
    SELECT * FROM returns_a
    UNION ALL
    SELECT * FROM returns_b
) AS combined
GROUP BY ROLLUP (ib_upper_bound, r_reason_desc)
ORDER BY total_return_amt DESC
LIMIT 100
