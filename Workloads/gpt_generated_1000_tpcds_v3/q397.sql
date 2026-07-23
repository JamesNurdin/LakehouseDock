WITH web_returns_agg AS (
    SELECT
        wr_returned_time_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_net_loss) AS total_web_net_loss
    FROM web_returns
    GROUP BY wr_returned_time_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    sm.sm_ship_mode_id,
    sm.sm_type,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    td.t_hour,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    cr.cr_return_amount,
    wr_agg.total_web_return_amt,
    wr_agg.total_web_net_loss,
    (cr.cr_net_loss + COALESCE(wr_agg.total_web_net_loss, 0)) AS total_warehouse_net_loss,
    RANK() OVER (PARTITION BY w.w_state ORDER BY (cr.cr_net_loss + COALESCE(wr_agg.total_web_net_loss, 0)) DESC) AS loss_rank_state,
    CASE
        WHEN cr.cr_return_amount > (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
        ) THEN 'Above Avg Return Amount'
        ELSE 'Below Avg Return Amount'
    END AS return_amount_category
FROM catalog_sales cs
INNER JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
INNER JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
INNER JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
INNER JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
INNER JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
INNER JOIN time_dim td_return ON cr.cr_returned_time_sk = td_return.t_time_sk
LEFT JOIN web_returns_agg wr_agg ON wr_agg.wr_returned_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 8 AND 17
    AND cd_bill.cd_purchase_estimate > 5000
    AND hd_bill.hd_income_band_sk IN (2, 3)
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND cr.cr_return_quantity > 1
    AND cr.cr_net_loss > 0
ORDER BY total_warehouse_net_loss DESC
LIMIT 100
