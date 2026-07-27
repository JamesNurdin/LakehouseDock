WITH refunded_demo AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        regexp_extract(hd.hd_buy_potential, '(high|medium|low)', 1) AS buy_potential_category,
        concat('BP_', hd.hd_buy_potential) AS buy_potential_concat,
        substring(hd.hd_buy_potential FROM 1 FOR 5) AS buy_potential_prefix
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(hd.hd_buy_potential, '(high|medium)')
      AND hd.hd_buy_potential LIKE '%potential%'
)
SELECT
    rd.ib_income_band_sk,
    rd.buy_potential_category,
    COUNT(DISTINCT rd.hd_demo_sk) AS household_cnt,
    SUM(rd.wr_return_amt) AS total_return_amt,
    AVG(rd.wr_return_amt) AS avg_return_amt
FROM refunded_demo rd
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_refunded_hdemo_sk = rd.hd_demo_sk
      AND wr2.wr_return_quantity >= 3
)
GROUP BY rd.ib_income_band_sk, rd.buy_potential_category
HAVING SUM(rd.wr_return_amt) > 5000
ORDER BY total_return_amt DESC
LIMIT 100
