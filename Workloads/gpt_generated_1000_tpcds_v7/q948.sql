WITH base_returns AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_returned_date_sk,
        sr.sr_fee
    FROM tpcds.store_returns AS sr
)
SELECT
    s1.s_store_name            AS store_name,
    s1.s_city                  AS store_city,
    r1.r_reason_desc           AS return_reason,
    ib.ib_lower_bound          AS income_lower,
    ib.ib_upper_bound          AS income_upper,
    COUNT(DISTINCT base_returns.sr_ticket_number) AS return_transactions,
    SUM(base_returns.sr_return_amt)                AS total_return_amount,
    AVG(base_returns.sr_return_quantity)           AS avg_return_quantity,
    SUM(CASE WHEN i.i_current_price > 100 THEN 1 ELSE 0 END) AS high_price_item_returns
FROM base_returns
JOIN tpcds.time_dim AS td
    ON base_returns.sr_return_time_sk = td.t_time_sk
JOIN tpcds.item AS i
    ON base_returns.sr_item_sk = i.i_item_sk
JOIN tpcds.item AS i2
    ON base_returns.sr_item_sk = i2.i_item_sk   -- second alias of item for join count
JOIN tpcds.household_demographics AS hd
    ON base_returns.sr_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band AS ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.store AS s1
    ON base_returns.sr_store_sk = s1.s_store_sk
JOIN tpcds.store AS s2
    ON base_returns.sr_store_sk = s2.s_store_sk   -- second alias of store for join count
JOIN tpcds.store AS s3
    ON base_returns.sr_store_sk = s3.s_store_sk   -- third alias of store for join count
JOIN tpcds.reason AS r1
    ON base_returns.sr_reason_sk = r1.r_reason_sk
JOIN tpcds.reason AS r2
    ON base_returns.sr_reason_sk = r2.r_reason_sk   -- second alias of reason for join count
WHERE i.i_rec_start_date >= DATE '1999-01-01'
GROUP BY
    s1.s_store_name,
    s1.s_city,
    r1.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY total_return_amount DESC
LIMIT 100
