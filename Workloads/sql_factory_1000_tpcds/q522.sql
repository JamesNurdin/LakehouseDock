SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) AS net_contribution,
    CASE
        WHEN SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss) > 0 THEN 'Positive'
        ELSE 'Negative'
    END AS contribution_flag,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) - SUM(cr.cr_net_loss)) DESC) AS profit_rank,
    AVG(hd.hd_income_band_sk) AS avg_income_band,
    COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders
FROM warehouse w
LEFT JOIN catalog_sales cs
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_warehouse_sk
