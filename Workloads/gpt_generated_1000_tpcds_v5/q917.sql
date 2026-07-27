WITH sr_wp AS (
    SELECT
        sr.sr_customer_sk,
        d_ret.d_year,
        hd.hd_income_band_sk,
        wp.wp_type,
        wp.wp_char_count,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_crt ON wp.wp_creation_date_sk = d_crt.d_date_sk
    WHERE d_ret.d_year = 2001                              -- filter 1: specific year
      AND hd.hd_income_band_sk BETWEEN 10 AND 16          -- filter 2: income band range
      AND c.c_birth_year BETWEEN 1950 AND 1965           -- filter 3: age cohort
      AND wp.wp_type IN ('article', 'review')            -- filter 4: page types of interest
      AND wp.wp_char_count > 1000                        -- filter 5: sufficiently long pages
),
agg AS (
    SELECT
        d_year,
        hd_income_band_sk,
        wp_type,
        SUM(sr_return_amt)   AS total_return_amt,
        SUM(sr_net_loss)     AS total_net_loss,
        COUNT(*)             AS return_cnt
    FROM sr_wp
    GROUP BY ROLLUP (d_year, hd_income_band_sk, wp_type)
)
SELECT
    d_year,
    hd_income_band_sk,
    wp_type,
    total_return_amt,
    total_net_loss,
    return_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS return_rank
FROM agg
ORDER BY d_year ASC, return_rank ASC NULLS LAST
LIMIT 100
