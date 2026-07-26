SELECT *
FROM (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS sales_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS return_loss,
        SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) AS net_profit,
        CASE
            WHEN SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0) > 1000 THEN 'High'
            ELSE 'Medium'
        END AS profit_category,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_sk ORDER BY (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) DESC) AS rn
    FROM warehouse w
    JOIN catalog_sales cs
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = cr.cr_returning_hdemo_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, cs.cs_item_sk, w.w_warehouse_sk
) t
WHERE t.rn <= 5
ORDER BY t.w_warehouse_id, t.rn
