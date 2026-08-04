WITH base_join AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_fee,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        sr.sr_net_loss,
        c.c_customer_sk,
        c.c_birth_year,
        c.c_birth_month,
        s.s_store_sk,
        s.s_store_name,
        s.s_tax_percentage,
        s.s_county,
        s.s_state,
        d.d_date_sk,
        d.d_year,
        d.d_moy,
        t.t_time_sk,
        t.t_hour
    FROM store_returns sr
    FULL OUTER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
),
 tax_array AS (
    SELECT
        bj.*,
        ARRAY[ bj.s_tax_percentage, bj.s_tax_percentage * 2 ] AS tax_arr
    FROM base_join bj
    WHERE bj.s_store_sk IS NOT NULL
),
 unnest_tax AS (
    SELECT
        bj.*,
        tax_val
    FROM tax_array bj
    CROSS JOIN UNNEST(bj.tax_arr) AS u(tax_val)
),
 missing_stores AS (
    SELECT sr_store_sk FROM store_returns
    EXCEPT
    SELECT s_store_sk FROM store
)
SELECT
    ut.s_state,
    ut.d_year,
    ut.t_hour,
    ut.tax_val,
    COUNT(*) AS cnt_returns,
    SUM(ut.sr_return_amt) AS total_return_amt,
    AVG(ut.sr_return_quantity) AS avg_return_qty,
    MIN(ut.sr_return_tax) AS min_return_tax,
    MAX(ut.sr_return_amt_inc_tax) AS max_return_amt_inc_tax,
    MAX(CASE WHEN ms.sr_store_sk IS NOT NULL THEN 1 ELSE 0 END) AS missing_store_flag
FROM unnest_tax ut
LEFT JOIN missing_stores ms
    ON ut.s_store_sk = ms.sr_store_sk
WHERE
    ut.d_year = 2020
    AND ut.d_moy IN (5, 8)
    AND ut.t_hour BETWEEN 9 AND 17
    AND ut.s_tax_percentage > 0.05
    AND ut.s_county = 'Mesa County'
    AND ut.c_birth_year BETWEEN 1950 AND 1980
    AND ut.sr_return_quantity > 0
GROUP BY
    ut.s_state,
    ut.d_year,
    ut.t_hour,
    ut.tax_val
ORDER BY total_return_amt DESC
LIMIT 100
