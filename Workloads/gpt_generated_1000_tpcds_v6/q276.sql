WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_hdemo_sk,
        sr_store_sk,
        sr_return_time_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_customer_sk, sr_hdemo_sk, sr_store_sk, sr_return_time_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    CASE
        WHEN ib.ib_upper_bound >= 100000 THEN 'Very High'
        WHEN ib.ib_upper_bound >= 75000  THEN 'High'
        ELSE 'Medium/Low'
    END AS income_band_category,
    SUM(sr_agg.total_return_amt) AS store_total_return_amt,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(sr_agg.total_return_amt) AS avg_return_per_customer,
    MIN(sr_agg.total_return_amt) AS min_return,
    MAX(sr_agg.total_return_amt) AS max_return
FROM sr_agg
JOIN customer c ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON sr_agg.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN time_dim t ON sr_agg.sr_return_time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND s.s_manager = 'David Thomas'
  AND ib.ib_lower_bound >= 50000
  AND c.c_birth_year BETWEEN 1960 AND 1980
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    CASE
        WHEN ib.ib_upper_bound >= 100000 THEN 'Very High'
        WHEN ib.ib_upper_bound >= 75000  THEN 'High'
        ELSE 'Medium/Low'
    END
HAVING SUM(sr_agg.total_return_amt) > 5000
ORDER BY store_total_return_amt DESC
LIMIT 100
