WITH item_returns AS (
    SELECT
        cr_item_sk,
        SUM(cr_net_loss) AS item_net_loss,
        SUM(cr_return_quantity) AS item_return_qty
    FROM catalog_returns
    GROUP BY cr_item_sk
)
SELECT
    i.i_category AS category,
    hd_ret.hd_vehicle_count AS vehicle_count,
    COUNT(DISTINCT cr.cr_order_number) AS num_orders,
    SUM(ir.item_return_qty) AS total_return_qty,
    SUM(ir.item_net_loss) AS total_net_loss,
    AVG(cr.cr_store_credit) AS avg_store_credit,
    COUNT(DISTINCT hd_ref.hd_demo_sk) AS num_refunded_households
FROM catalog_returns cr
JOIN item_returns ir
    ON cr.cr_item_sk = ir.cr_item_sk
JOIN item i
    ON i.i_item_sk = cr.cr_item_sk
JOIN household_demographics hd_ret
    ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE cr.cr_store_credit > 20.00
  AND i.i_current_price BETWEEN 10 AND 1000
  AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
GROUP BY i.i_category, hd_ret.hd_vehicle_count
HAVING SUM(ir.item_return_qty) > 5
ORDER BY total_net_loss DESC
LIMIT 10
