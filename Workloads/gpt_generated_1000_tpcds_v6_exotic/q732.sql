WITH filtered AS (
    SELECT
        sr.sr_return_amt_inc_tax,
        sr.sr_store_credit,
        sr.sr_return_quantity,
        d.d_year,
        d.d_current_week,
        d.d_following_holiday,
        s.s_state,
        s.s_company_name,
        hd.hd_income_band_sk,
        wp.wp_url
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_current_week = 'N'
      AND d.d_following_holiday = 'N'
      AND s.s_company_name = 'Unknown'
      AND hd.hd_income_band_sk = 5
      AND sr.sr_return_amt_inc_tax > 500
),
agg AS (
    SELECT
        d_year,
        s_state,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        AVG(sr_store_credit) AS avg_store_credit,
        MIN(sr_return_quantity) AS min_qty,
        MAX(sr_return_quantity) AS max_qty
    FROM filtered
    GROUP BY d_year, s_state
    HAVING SUM(sr_return_amt_inc_tax) > 5000
)
SELECT
    d_year,
    s_state,
    return_cnt,
    total_return_amt,
    avg_store_credit,
    min_qty,
    max_qty,
    SUM(total_return_amt) OVER (PARTITION BY s_state) AS state_total_return,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_return_amt DESC) AS state_rank
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
