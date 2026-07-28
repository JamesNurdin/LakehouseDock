WITH
    union_reason AS (
        SELECT r.r_reason_sk, r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_desc LIKE '%damaged%'
        UNION ALL
        SELECT r.r_reason_sk, r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_desc LIKE '%not as described%'
    )
SELECT
    s.s_store_name,
    p.p_promo_name,
    d_ret.d_year,
    r.r_reason_desc,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    (
        SELECT AVG(wr_sub.wr_return_amt)
        FROM web_returns wr_sub
    ) AS overall_avg_return_amt
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN income_band ib_ret
    ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
JOIN income_band ib_ref
    ON hd_ref.hd_income_band_sk = ib_ref.ib_income_band_sk
WHERE d_ret.d_year = 2001
  AND t.t_hour BETWEEN 8 AND 20
  AND hd_ret.hd_vehicle_count >= 0
  AND ib_ret.ib_upper_bound > 20000
  AND r.r_reason_desc IN (SELECT r2.r_reason_desc FROM union_reason r2)
GROUP BY
    s.s_store_name,
    p.p_promo_name,
    d_ret.d_year,
    r.r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
