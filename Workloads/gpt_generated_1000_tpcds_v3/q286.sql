WITH base_returns AS (
    SELECT
        WR.wr_return_quantity,
        WR.wr_return_amt,
        WR.wr_return_amt_inc_tax,
        WR.wr_net_loss,
        I.i_item_sk,
        I.i_brand,
        I.i_category,
        I.i_current_price,
        HD.hd_buy_potential,
        HD.hd_vehicle_count,
        INV.inv_quantity_on_hand,
        TD.t_hour,
        R.r_reason_desc
    FROM web_returns WR
    JOIN time_dim TD ON WR.wr_returned_time_sk = TD.t_time_sk
    JOIN item I ON WR.wr_item_sk = I.i_item_sk
    JOIN reason R ON WR.wr_reason_sk = R.r_reason_sk
    JOIN customer C ON WR.wr_refunded_customer_sk = C.c_customer_sk
    JOIN household_demographics HD ON WR.wr_refunded_hdemo_sk = HD.hd_demo_sk
    JOIN inventory INV ON INV.inv_item_sk = I.i_item_sk
    JOIN promotion P ON P.p_item_sk = I.i_item_sk
    WHERE
        I.i_current_price > 100.00
        AND HD.hd_buy_potential = '1001-5000'
        AND HD.hd_vehicle_count >= 2
        AND INV.inv_quantity_on_hand < 50
        AND TD.t_hour BETWEEN 9 AND 17
        AND R.r_reason_desc LIKE '%damaged%'
),
agg_returns AS (
    SELECT
        i_brand,
        i_category,
        t_hour,
        hd_buy_potential,
        i_item_sk,
        COUNT(*) AS return_cnt,
        SUM(wr_return_amt) AS total_return_amt,
        AVG(wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        MIN(wr_return_quantity) AS min_return_qty,
        MAX(wr_return_quantity) AS max_return_qty
    FROM base_returns
    GROUP BY i_brand, i_category, t_hour, hd_buy_potential, i_item_sk
)
SELECT
    a.i_brand,
    a.i_category,
    a.t_hour,
    a.hd_buy_potential,
    a.return_cnt,
    a.total_return_amt,
    a.avg_return_amt_inc_tax,
    a.min_return_qty,
    a.max_return_qty,
    (SELECT MIN(p_cost) FROM promotion p_sub WHERE p_sub.p_item_sk = a.i_item_sk) AS min_promo_cost,
    SUM(a.total_return_amt) OVER (PARTITION BY a.i_brand ORDER BY a.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_brand_return_amt
FROM agg_returns a
ORDER BY a.total_return_amt DESC
LIMIT 100
