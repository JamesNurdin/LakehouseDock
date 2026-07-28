/* Goal: Calculate total return amount per company and promotion for the year 2002, filtered by household income band, call‑center state, active promotions, business hours and high web‑return fees, then rank companies by their total return amount. */
WITH sr_join AS (
    SELECT
        cc.cc_company_name        AS company_name,
        p.p_promo_name            AS promo_name,
        d_sr.d_year               AS year,
        sr.sr_return_amt          AS return_amt,
        t_sr.t_hour               AS hour
    FROM store_returns sr
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sr.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_sr.d_date_sk
    WHERE d_sr.d_year = 2002
      AND hd_sr.hd_income_band_sk IN (4, 10, 16)
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t_sr.t_hour BETWEEN 9 AND 17
),
wr_join AS (
    SELECT
        cc.cc_company_name        AS company_name,
        p.p_promo_name            AS promo_name,
        d_wr.d_year               AS year,
        wr.wr_return_amt          AS return_amt,
        t_wr.t_hour               AS hour
    FROM web_returns wr
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN household_demographics hd_wr
        ON wr.wr_returning_hdemo_sk = hd_wr.hd_demo_sk
    JOIN call_center cc
        ON cc.cc_open_date_sk = d_wr.d_date_sk
    JOIN promotion p
        ON p.p_end_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2002
      AND hd_wr.hd_income_band_sk IN (4, 10, 16)
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND t_wr.t_hour BETWEEN 9 AND 17
      AND wr.wr_fee > 50
),
combined AS (
    SELECT company_name, promo_name, year, return_amt FROM sr_join
    UNION ALL
    SELECT company_name, promo_name, year, return_amt FROM wr_join
)
SELECT
    company_name,
    promo_name,
    year,
    SUM(return_amt)                     AS total_return_amount,
    COUNT(*)                            AS return_count,
    ROW_NUMBER() OVER (PARTITION BY company_name ORDER BY SUM(return_amt) DESC) AS company_rank
FROM combined
GROUP BY company_name, promo_name, year
ORDER BY total_return_amount DESC
LIMIT 100
