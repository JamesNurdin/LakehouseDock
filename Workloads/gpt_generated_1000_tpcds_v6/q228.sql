WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_hdemo_sk,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        d_ret.d_year,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2001
      AND r.r_reason_desc = 'Damaged'
      AND sr.sr_return_amt > 0
)
SELECT
    s.s_store_id,
    d_closure.d_year AS closure_year,
    CASE
        WHEN ib.ib_upper_bound <= 60000 THEN 'Low Income'
        WHEN ib.ib_upper_bound <= 120000 THEN 'Mid Income'
        ELSE 'High Income'
    END AS income_category,
    COUNT(fr.sr_return_amt) AS returns_count,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_return_amt) AS avg_return_amt,
    MIN(fr.sr_return_amt) AS min_return_amt,
    MAX(fr.sr_return_amt) AS max_return_amt,
    SUM(CASE WHEN fr.sr_net_loss > 0 THEN fr.sr_net_loss ELSE 0 END) AS total_net_loss
FROM filtered_returns fr
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
JOIN household_demographics hd
    ON fr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE s.s_floor_space > 8000000
  AND s.s_state = 'CA'
  AND ib.ib_upper_bound <= 100000
GROUP BY
    s.s_store_id,
    d_closure.d_year,
    CASE
        WHEN ib.ib_upper_bound <= 60000 THEN 'Low Income'
        WHEN ib.ib_upper_bound <= 120000 THEN 'Mid Income'
        ELSE 'High Income'
    END
ORDER BY total_return_amt DESC
LIMIT 100
