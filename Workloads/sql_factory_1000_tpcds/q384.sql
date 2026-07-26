WITH daily_margin AS (
    SELECT
        sr.sr_store_sk,
        ca.ca_state,
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt - i.i_wholesale_cost * sr.sr_return_quantity) AS daily_margin,
        SUM(sr.sr_return_quantity) AS daily_quantity
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY sr.sr_store_sk, ca.ca_state, sr.sr_returned_date_sk
),
store_total AS (
    SELECT
        sr_store_sk,
        ca_state,
        SUM(daily_margin) AS total_margin,
        SUM(daily_quantity) AS total_quantity
    FROM daily_margin
    GROUP BY sr_store_sk, ca_state
)
SELECT
    dt.sr_store_sk,
    dt.ca_state,
    dt.sr_returned_date_sk,
    dt.daily_margin,
    SUM(dt.daily_margin) OVER (PARTITION BY dt.sr_store_sk ORDER BY dt.sr_returned_date_sk ROWS UNBOUNDED PRECEDING) AS cumulative_margin,
    t.total_margin,
    t.total_margin / NULLIF(t.total_quantity, 0) AS avg_margin_per_item,
    DENSE_RANK() OVER (ORDER BY t.total_margin DESC) AS store_margin_rank,
    CASE
        WHEN t.total_margin < 0 THEN 'Loss'
        WHEN t.total_margin BETWEEN 0 AND 10000 THEN 'BreakEven'
        ELSE 'Profit'
    END AS profit_category
FROM daily_margin dt
JOIN store_total t
    ON dt.sr_store_sk = t.sr_store_sk
    AND dt.ca_state = t.ca_state
ORDER BY store_margin_rank, dt.sr_store_sk, dt.sr_returned_date_sk
