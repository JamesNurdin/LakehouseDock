WITH agg_wr AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_hdemo_sk,
        wr_returning_hdemo_sk,
        SUM(wr_return_amt)            AS total_return_amt,
        SUM(wr_return_quantity)       AS total_return_qty,
        AVG(wr_return_amt)            AS avg_return_amt,
        SUM(wr_net_loss)              AS total_net_loss,
        COUNT(*)                      AS return_cnt
    FROM web_returns
    GROUP BY
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_hdemo_sk,
        wr_returning_hdemo_sk
)
SELECT
    d.d_year,
    i.i_category,
    hd_refunded.hd_buy_potential,
    SUM(agg.total_return_amt)            AS total_return_amt,
    SUM(agg.total_return_qty)            AS total_return_qty,
    COUNT(*)                             AS return_group_cnt,
    AVG(i.i_current_price)               AS avg_price,
    MIN(i.i_current_price)               AS min_price,
    MAX(i.i_current_price)               AS max_price,
    CASE WHEN SUM(agg.total_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS return_amt_flag,
    CASE WHEN AVG(i.i_current_price) > 100 THEN 'Premium' ELSE 'Standard' END AS price_category
FROM agg_wr agg
JOIN date_dim d
    ON agg.wr_returned_date_sk = d.d_date_sk
JOIN item i
    ON agg.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_refunded
    ON agg.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON agg.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE
    d.d_quarter_name = '1903Q3'
    AND i.i_units = 'Box'
    AND hd_refunded.hd_buy_potential = '>10000'
    AND hd_returning.hd_vehicle_count = 2
    AND d.d_date_sk IN (SELECT DISTINCT wr_returned_date_sk FROM web_returns)
GROUP BY
    d.d_year,
    i.i_category,
    hd_refunded.hd_buy_potential
HAVING
    SUM(agg.total_return_amt) > 1000
ORDER BY
    total_return_amt DESC
LIMIT 100
