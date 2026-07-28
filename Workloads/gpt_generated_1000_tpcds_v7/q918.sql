/*
  Goal: Analyze total return amount, average fee and return counts per customer demographic and return reason, while also capturing detailed return quantity and income‑band characteristics. The query pre‑aggregates store return data in a CTE, then joins all five selected tables and re‑uses the household_demographics and income_band tables under different aliases to reach nine join clauses.
*/
WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_hdemo_sk,
        sr_reason_sk,
        SUM(sr_return_amt_inc_tax)          AS total_return_amt,
        AVG(sr_fee)                         AS avg_fee,
        COUNT(*)                            AS cnt_returns
    FROM store_returns
    WHERE sr_return_amt_inc_tax > 200
    GROUP BY sr_customer_sk, sr_hdemo_sk, sr_reason_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd_current.hd_buy_potential          AS current_buy_potential,
    hd_current.hd_income_band_sk         AS current_income_band_sk,
    ib_current.ib_lower_bound           AS current_income_low,
    ib_current.ib_upper_bound           AS current_income_high,
    r.r_reason_desc                      AS reason_description,
    sr_agg.total_return_amt,
    sr_agg.avg_fee,
    sr_agg.cnt_returns,
    hd_return.hd_dep_count               AS return_hd_dep_count,
    ib_return.ib_upper_bound             AS return_income_upper,
    SUM(sr_detail.sr_return_quantity)    AS total_return_quantity
FROM sr_agg
JOIN customer c
    ON sr_agg.sr_customer_sk = c.c_customer_sk                                   -- join 1
JOIN household_demographics hd_current
    ON c.c_current_hdemo_sk = hd_current.hd_demo_sk                              -- join 2
JOIN income_band ib_current
    ON hd_current.hd_income_band_sk = ib_current.ib_income_band_sk               -- join 3
JOIN reason r
    ON sr_agg.sr_reason_sk = r.r_reason_sk                                      -- join 4
JOIN household_demographics hd_return
    ON sr_agg.sr_hdemo_sk = hd_return.hd_demo_sk                                 -- join 5
JOIN income_band ib_return
    ON hd_return.hd_income_band_sk = ib_return.ib_income_band_sk                 -- join 6
JOIN store_returns sr_detail
    ON sr_detail.sr_customer_sk = c.c_customer_sk                               -- join 7
JOIN household_demographics hd_detail
    ON sr_detail.sr_hdemo_sk = hd_detail.hd_demo_sk                             -- join 8
JOIN income_band ib_detail
    ON hd_detail.hd_income_band_sk = ib_detail.ib_income_band_sk                 -- join 9
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd_current.hd_buy_potential,
    hd_current.hd_income_band_sk,
    ib_current.ib_lower_bound,
    ib_current.ib_upper_bound,
    r.r_reason_desc,
    sr_agg.total_return_amt,
    sr_agg.avg_fee,
    sr_agg.cnt_returns,
    hd_return.hd_dep_count,
    ib_return.ib_upper_bound
