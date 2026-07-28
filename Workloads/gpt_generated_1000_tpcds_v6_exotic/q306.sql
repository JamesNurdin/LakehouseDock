WITH warehouse_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        w.w_warehouse_name,
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE 
            WHEN SUM(cr.cr_net_loss) > 1000 THEN 'HIGH'
            WHEN SUM(cr.cr_net_loss) BETWEEN 500 AND 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 50
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 50000
      AND w.w_state = 'CA'
    GROUP BY cr.cr_warehouse_sk, w.w_warehouse_name, cr.cr_item_sk
)
SELECT
    wr.cr_warehouse_sk,
    wr.w_warehouse_name,
    wr.cr_item_sk,
    wr.total_return_amount,
    wr.total_net_loss,
    wr.loss_category,
    i.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY wr.cr_warehouse_sk ORDER BY wr.total_return_amount DESC) AS rn_item_by_return,
    RANK() OVER (PARTITION BY wr.w_warehouse_name ORDER BY wr.total_net_loss DESC) AS rank_warehouse_by_loss,
    (SELECT MAX(ib_upper) FROM (SELECT ib.ib_upper_bound AS ib_upper FROM income_band ib) t) AS max_income_upper_bound
FROM warehouse_returns wr
JOIN inventory i
    ON i.inv_warehouse_sk = wr.cr_warehouse_sk
WHERE i.inv_quantity_on_hand > 0
  AND i.inv_date_sk BETWEEN 2450800 AND 2451100
ORDER BY wr.total_return_amount DESC, rn_item_by_return
LIMIT 100
