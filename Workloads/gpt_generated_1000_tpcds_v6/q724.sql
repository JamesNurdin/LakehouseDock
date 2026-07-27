/* goal: Analyze store return amounts by income band and time shift, extracting numeric ranges from the household buy‑potential field, filtering time IDs with a LIKE pattern, classifying total returns with CASE, and showing a running total per hour */
WITH filtered_returns AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_tax,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        sr.sr_hdemo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        td.t_time_id,
        td.t_shift,
        td.t_hour,
        -- extract the lower bound of the buy‑potential range (e.g., "5001-10000" -> 5001)
        CAST(regexp_extract(hd.hd_buy_potential, '^([0-9]+)-', 1) AS integer) AS buy_potential_low,
        -- extract the upper bound of the buy‑potential range (e.g., "5001-10000" -> 10000)
        CAST(regexp_extract(hd.hd_buy_potential, '-([0-9]+)$', 1) AS integer) AS buy_potential_high
    FROM store_returns sr
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_time_id LIKE 'AAAAAAA%AAAAAAA'                     -- pattern match on the time identifier
      AND regexp_like(hd.hd_buy_potential, '^[0-9]+-[0-9]+$')      -- keep only numeric ranges
      AND CAST(regexp_extract(hd.hd_buy_potential, '^([0-9]+)-', 1) AS integer) >= 5000
)
,
aggregated AS (
    SELECT
        ib_income_band_sk,
        CONCAT('Band_', CAST(ib_income_band_sk AS varchar)) AS income_band_label,
        t_shift,
        t_hour,
        COUNT(*) AS returns_count,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        CASE
            WHEN SUM(sr_return_amt) > 10000 THEN 'High'
            ELSE 'Medium'
        END AS return_level
    FROM filtered_returns
    GROUP BY ib_income_band_sk, t_shift, t_hour
)
SELECT
    ib_income_band_sk,
    income_band_label,
    t_shift,
    t_hour,
    returns_count,
    total_return_amt,
    avg_return_amt,
    return_level,
    -- running total of return amount per income band ordered by hour
    SUM(total_return_amt) OVER (PARTITION BY ib_income_band_sk ORDER BY t_hour
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_by_hour
FROM aggregated
ORDER BY total_return_amt DESC
LIMIT 100
