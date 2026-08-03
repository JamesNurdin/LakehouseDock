WITH catalog_fact AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_addr_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        ca_refund.ca_state        AS refund_state,
        ca_return.ca_state        AS returning_state,
        sm.sm_type                AS ship_type,
        w.w_warehouse_name        AS warehouse_name,
        r.r_reason_desc           AS reason_desc,
        d.d_year,
        d.d_month_seq,
        d.d_date
    FROM catalog_returns AS cr
    JOIN customer_address AS ca_refund   ON cr.cr_refunded_addr_sk   = ca_refund.ca_address_sk
    JOIN customer_address AS ca_return   ON cr.cr_returning_addr_sk   = ca_return.ca_address_sk
    JOIN ship_mode       AS sm           ON cr.cr_ship_mode_sk       = sm.sm_ship_mode_sk
    JOIN warehouse       AS w            ON cr.cr_warehouse_sk       = w.w_warehouse_sk
    JOIN reason          AS r            ON cr.cr_reason_sk          = r.r_reason_sk
    JOIN date_dim        AS d            ON cr.cr_returned_date_sk   = d.d_date_sk
    WHERE d.d_year = 2001                      -- filter 1
      AND sm.sm_type = 'AIR'                  -- filter 2
      AND w.w_warehouse_sq_ft > 600000        -- filter 3
),
expanded_amounts AS (
    SELECT
        cf.*, 
        amt.amount_value,
        amt.amount_idx
    FROM catalog_fact AS cf
    CROSS JOIN LATERAL (
        SELECT ARRAY[cf.cr_return_amount, cf.cr_return_tax, cf.cr_net_loss] AS arr
    ) AS a
    CROSS JOIN UNNEST(a.arr) WITH ORDINALITY AS amt(amount_value, amount_idx)
)
SELECT
    ea.cr_returned_date_sk,
    ea.d_date,
    ea.ship_type,
    ea.warehouse_name,
    ea.reason_desc,
    ea.amount_idx,
    ea.amount_value,
    ea.refund_state,
    ea.returning_state,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    ws.web_name,
    ws.web_state,
    -- correlated scalar subquery: total store return amount for the same date
    (SELECT SUM(sr_sub.sr_return_amt)
     FROM store_returns AS sr_sub
     WHERE sr_sub.sr_returned_date_sk = ea.cr_returned_date_sk) AS total_store_return_amt,
    -- window rank per reason_desc ordered by net loss descending
    ROW_NUMBER() OVER (PARTITION BY ea.reason_desc ORDER BY ea.cr_net_loss DESC) AS rn_reason
FROM expanded_amounts AS ea
JOIN store_returns AS sr ON sr.sr_returned_date_sk = ea.cr_returned_date_sk
JOIN web_returns   AS wr ON wr.wr_returned_date_sk = ea.cr_returned_date_sk
JOIN web_site      AS ws ON ws.web_open_date_sk   = ea.cr_returned_date_sk
WHERE sr.sr_return_quantity > 0                     -- additional filter
  AND wr.wr_return_amt > 0.0                        -- additional filter
  AND ws.web_state = 'CA'                           -- additional filter
ORDER BY rn_reason, ea.amount_value DESC
LIMIT 100
