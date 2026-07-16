WITH aggregated AS (
    SELECT
        d_ret.d_year,
        d_ret.d_quarter_name,
        sm.sm_type,
        sm.sm_carrier,
        st.s_state,
        ws.web_name,
        d_ret.d_month_seq,
        COUNT(DISTINCT cr.cr_order_number) AS num_orders,
        SUM(cr.cr_return_amount) AS total_return_amt,
        AVG(cr.cr_return_amount) AS avg_return_amt,
        SUM(cr.cr_fee) AS total_fee,
        MAX(cr.cr_return_quantity) AS max_return_qty,
        MIN(cr.cr_return_quantity) AS min_return_qty,
        SUM(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount ELSE 0 END) AS positive_return_amt,
        SUM(CASE WHEN cr.cr_return_amount < 0 THEN cr.cr_return_amount ELSE 0 END) AS negative_return_amt,
        SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_fee), 0) AS return_fee_ratio,
        CASE
            WHEN d_ret.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
            WHEN d_ret.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
            WHEN d_ret.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS quarter_bucket,
        d_ret.d_date,
        d_ws_close.d_date AS ws_close_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store st
        ON st.s_closed_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ws_close
        ON ws.web_close_date_sk = d_ws_close.d_date_sk
    WHERE d_ret.d_year BETWEEN 2020 AND 2022
      AND sm.sm_carrier IN ('UPS', 'FedEx', 'DHL')
      AND st.s_state IN ('CA', 'NY', 'TX')
      AND d_ws_close.d_date >= d_ret.d_date
    GROUP BY
        d_ret.d_year,
        d_ret.d_quarter_name,
        sm.sm_type,
        sm.sm_carrier,
        st.s_state,
        ws.web_name,
        d_ret.d_month_seq,
        d_ret.d_date,
        d_ws_close.d_date
)
SELECT
    a.d_year,
    a.d_quarter_name,
    a.sm_type,
    a.sm_carrier,
    a.s_state,
    a.web_name,
    a.quarter_bucket,
    a.num_orders,
    a.total_return_amt,
    a.avg_return_amt,
    a.total_fee,
    a.max_return_qty,
    a.min_return_qty,
    a.positive_return_amt,
    a.negative_return_amt,
    a.return_fee_ratio,
    ROW_NUMBER() OVER (PARTITION BY a.sm_type ORDER BY a.total_return_amt DESC) AS rn_by_ship_type,
    SUM(a.total_return_amt) OVER (PARTITION BY a.d_year) AS year_total_return_amt
FROM aggregated a
WHERE a.total_return_amt > 1000
ORDER BY a.total_return_amt DESC
LIMIT 100
