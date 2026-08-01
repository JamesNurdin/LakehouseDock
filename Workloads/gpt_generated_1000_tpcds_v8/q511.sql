WITH
    filtered_returns AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_hdemo_sk,
            sr.sr_reason_sk,
            sr.sr_return_amt,
            r.r_reason_desc,
            hd.hd_buy_potential,
            hd.hd_dep_count,
            hd.hd_vehicle_count,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM store_returns sr
        JOIN household_demographics hd
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
        WHERE hd.hd_buy_potential LIKE '%5000%'
          AND ib.ib_upper_bound > 50000
          AND r.r_reason_desc NOT LIKE '%model%'
    ),
    ranked_returns AS (
        SELECT
            fr.sr_ticket_number,
            fr.sr_hdemo_sk,
            fr.sr_reason_sk,
            fr.sr_return_amt,
            fr.r_reason_desc,
            fr.ib_lower_bound,
            fr.ib_upper_bound,
            CASE
                WHEN fr.sr_return_amt > 1000 THEN 'High'
                WHEN fr.sr_return_amt BETWEEN 500 AND 1000 THEN 'Medium'
                ELSE 'Low'
            END AS amt_category,
            ROW_NUMBER() OVER (PARTITION BY fr.r_reason_desc ORDER BY fr.sr_return_amt DESC) AS rn,
            RANK() OVER (ORDER BY fr.sr_return_amt DESC) AS overall_rank
        FROM filtered_returns fr
    ),
    key_set_a AS (
        SELECT sr_ticket_number FROM filtered_returns WHERE sr_return_amt > 2000
    ),
    key_set_b AS (
        SELECT sr_ticket_number FROM filtered_returns WHERE sr_return_amt < 100
    ),
    diff_keys AS (
        SELECT sr_ticket_number FROM key_set_a
        EXCEPT
        SELECT sr_ticket_number FROM key_set_b
    ),
    intersect_keys AS (
        SELECT sr_ticket_number FROM filtered_returns WHERE hd_dep_count >= 5
        INTERSECT
        SELECT sr_ticket_number FROM filtered_returns WHERE hd_vehicle_count >= 2
    ),
    cross_product AS (
        SELECT d.bucket, k.sr_ticket_number
        FROM (VALUES (1), (2), (3)) AS d(bucket)
        CROSS JOIN (
            SELECT sr_ticket_number FROM diff_keys LIMIT 10
        ) AS k
    ),
    full_hd_ib AS (
        SELECT
            hd.hd_demo_sk,
            hd.hd_income_band_sk,
            hd.hd_buy_potential,
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound
        FROM household_demographics hd
        FULL OUTER JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    )
SELECT
    rr.r_reason_desc,
    rr.amt_category,
    rr.sr_return_amt,
    rr.rn,
    rr.overall_rank,
    f.hd_buy_potential,
    f.ib_lower_bound,
    f.ib_upper_bound,
    cp.bucket
FROM ranked_returns rr
FULL OUTER JOIN full_hd_ib f
    ON rr.sr_hdemo_sk = f.hd_demo_sk
JOIN cross_product cp
    ON rr.sr_ticket_number = cp.sr_ticket_number
WHERE rr.rn <= 5
  AND rr.sr_ticket_number IN (SELECT sr_ticket_number FROM intersect_keys)
  AND EXISTS (
        SELECT 1 FROM reason r3
        WHERE r3.r_reason_sk = rr.sr_reason_sk
          AND r3.r_reason_desc = 'Package was damaged'
      )
ORDER BY rr.overall_rank ASC
LIMIT 100
