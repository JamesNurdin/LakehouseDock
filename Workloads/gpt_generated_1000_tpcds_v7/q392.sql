WITH filtered AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_item_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_amt_inc_tax,
        wr.wr_refunded_cash,
        wr.wr_net_loss
    FROM web_returns wr
    -- selective predicates on the web_returns row itself
    WHERE wr.wr_refunded_cash > 200.00
      AND wr.wr_return_quantity >= 1
)
SELECT
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    hd_ref.hd_vehicle_count,
    COUNT(*)                                     AS cnt_returns,
    SUM(f.wr_return_amt_inc_tax)                 AS total_return_amount_inc_tax,
    SUM(f.wr_return_quantity)                    AS total_return_quantity,
    AVG(f.wr_refunded_cash)                      AS avg_refunded_cash,
    MIN(f.wr_return_amt)                         AS min_return_amount,
    MAX(f.wr_return_amt)                         AS max_return_amount
FROM filtered f
JOIN date_dim d ON f.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON f.wr_returned_time_sk = t.t_time_sk
JOIN item i ON f.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_ref ON f.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret ON f.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE d.d_fy_week_seq BETWEEN 5 AND 12                -- fiscal week filter
  AND d.d_month_seq IN (1, 2, 3)                       -- first quarter months
  AND i.i_current_price BETWEEN 10.00 AND 100.00       -- price range filter
  AND hd_ref.hd_vehicle_count >= 1                     -- households with at least one vehicle
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31' -- calendar year filter
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    hd_ref.hd_vehicle_count
ORDER BY total_return_amount_inc_tax DESC
