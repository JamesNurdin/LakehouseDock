WITH base_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_reversed_charge,
        sr.sr_store_credit,
        d_return.d_year,
        d_return.d_fy_year,
        d_return.d_current_day AS return_current_day,
        t.t_hour,
        s.s_state,
        s.s_store_name,
        s.s_closed_date_sk,
        d_closed.d_current_day AS closed_current_day
    FROM store_returns sr
    JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_return.d_fy_year = 1903
      AND d_return.d_current_day = 'N'
      AND d_closed.d_current_day = 'N'
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND sr.sr_store_credit > 1000
),
union_returns AS (
    SELECT
        br.sr_returned_date_sk,
        br.sr_return_time_sk,
        br.sr_item_sk,
        br.sr_store_sk,
        br.sr_ticket_number,
        br.sr_return_quantity,
        br.sr_return_amt_inc_tax,
        br.sr_reversed_charge,
        br.sr_store_credit,
        br.d_year,
        br.d_fy_year,
        br.return_current_day,
        br.t_hour,
        br.s_state,
        br.s_store_name,
        br.s_closed_date_sk,
        br.closed_current_day
    FROM base_returns br
    WHERE EXISTS (
        SELECT 1
        FROM item i
        WHERE i.i_item_sk = br.sr_item_sk
          AND i.i_class = 'infants'
          AND i.i_manufact_id IN (220, 260)
    )
    UNION
    SELECT
        br.sr_returned_date_sk,
        br.sr_return_time_sk,
        br.sr_item_sk,
        br.sr_store_sk,
        br.sr_ticket_number,
        br.sr_return_quantity,
        br.sr_return_amt_inc_tax,
        br.sr_reversed_charge,
        br.sr_store_credit,
        br.d_year,
        br.d_fy_year,
        br.return_current_day,
        br.t_hour,
        br.s_state,
        br.s_store_name,
        br.s_closed_date_sk,
        br.closed_current_day
    FROM base_returns br
    WHERE EXISTS (
        SELECT 1
        FROM item i
        WHERE i.i_item_sk = br.sr_item_sk
          AND i.i_class = 'toddlers'
          AND i.i_manufact_id IN (220, 260)
    )
)
SELECT
    ur.d_year AS fiscal_year,
    ur.s_store_name AS store_name,
    ur.s_state AS state,
    COUNT(*) AS total_returns,
    SUM(ur.sr_return_amt_inc_tax) AS total_return_amount,
    AVG(ur.sr_return_amt_inc_tax) AS avg_return_amount,
    SUM(CASE WHEN ur.sr_return_amt_inc_tax > 500 THEN ur.sr_return_amt_inc_tax ELSE 0 END) AS sum_high_value_returns,
    SUM(CASE WHEN ur.sr_reversed_charge > 0 THEN ur.sr_reversed_charge ELSE 0 END) AS total_reversed_charge,
    COUNT(CASE WHEN ur.sr_store_credit > 1500 THEN 1 END) AS high_credit_return_cnt,
    MIN(ur.sr_return_amt_inc_tax) AS min_return_amount,
    MAX(ur.sr_return_amt_inc_tax) AS max_return_amount
FROM union_returns ur
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ur.sr_ticket_number
      AND sr2.sr_return_quantity = 0
)
GROUP BY ur.d_year, ur.s_store_name, ur.s_state
ORDER BY total_return_amount DESC
LIMIT 100
