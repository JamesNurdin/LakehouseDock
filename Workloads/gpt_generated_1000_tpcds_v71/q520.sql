WITH base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_customer_sk,
        sr.sr_reason_sk,
        sr.sr_return_time_sk,
        d.d_date,
        d.d_year,
        s.s_store_name,
        s.s_store_id,
        s.s_number_employees,
        r.r_reason_desc,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        cc.cc_state,
        wp.wp_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
        AND d.d_date_sk = wp.wp_creation_date_sk
    WHERE d.d_year = 2001
      AND s.s_number_employees BETWEEN 200 AND 300
      AND sr.sr_return_tax > 10
      AND r.r_reason_desc LIKE '%damaged%'
      AND (cc.cc_state = 'CA' OR cc.cc_state IS NULL)
      AND (wp.wp_type = 'article' OR wp.wp_type IS NULL)
)
SELECT
    d_date,
    s_store_name,
    s_store_id,
    total_return_amt,
    store_rank
FROM (
    SELECT
        d_date,
        s_store_name,
        s_store_id,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY SUM(sr_return_amt) DESC) AS store_rank
    FROM base
    GROUP BY d_date, s_store_name, s_store_id
) t
WHERE store_rank <= 5
ORDER BY d_date DESC, store_rank
LIMIT 100
