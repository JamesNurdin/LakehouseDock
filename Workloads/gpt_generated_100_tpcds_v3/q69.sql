WITH web_return_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_net_loss) AS total_web_net_loss,
        COUNT(DISTINCT wr_order_number) AS web_order_cnt
    FROM web_returns
    WHERE wr_return_amt > 50.00
    GROUP BY wr_item_sk
)
SELECT
    cp.cp_department,
    i.i_brand,
    w.w_state,
    cd_refunded.cd_credit_rating,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(COALESCE(wra.total_web_return_amt, 0)) AS total_web_return_amount,
    SUM(COALESCE(wra.total_web_net_loss, 0)) AS total_web_net_loss,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty_on_hand,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    SUM(COALESCE(wra.web_order_cnt, 0)) AS web_order_cnt,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS avg_price_for_brand
FROM catalog_returns cr
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_return_agg wra ON wra.wr_item_sk = i.i_item_sk
WHERE
    cd_refunded.cd_credit_rating = 'High Risk'
    AND i.i_current_price >= 100.00
    AND cp.cp_department = 'Electronics'
    AND inv.inv_quantity_on_hand > 10
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
GROUP BY
    cp.cp_department,
    i.i_brand,
    w.w_state,
    cd_refunded.cd_credit_rating,
    sm.sm_type
ORDER BY
    total_catalog_return_amount DESC,
    total_web_return_amount DESC
LIMIT 100
