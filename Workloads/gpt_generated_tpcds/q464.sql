WITH returns_2022 AS (
    SELECT
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        c.cd_gender,
        h.hd_income_band_sk,
        r.r_reason_desc,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        sr.sr_return_amt
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics c
        ON sr.sr_cdemo_sk = c.cd_demo_sk
    JOIN household_demographics h
        ON sr.sr_hdemo_sk = h.hd_demo_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND (d_closed.d_date IS NULL OR d_closed.d_date > d.d_date)
)
SELECT
    s_store_name,
    s_state,
    d_year,
    d_month_seq,
    cd_gender,
    hd_income_band_sk,
    r_reason_desc,
    COUNT(*) AS return_count,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_return_amt) AS avg_return_amount,
    SUM(sr_return_quantity) AS total_quantity
FROM returns_2022
GROUP BY
    s_store_name,
    s_state,
    d_year,
    d_month_seq,
    cd_gender,
    hd_income_band_sk,
    r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
