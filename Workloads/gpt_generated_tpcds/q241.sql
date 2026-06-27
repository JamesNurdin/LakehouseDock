SELECT
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    hd.hd_income_band_sk,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS sales_orders,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales_amount,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_profit_after_returns,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
GROUP BY
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    hd.hd_income_band_sk,
    r.r_reason_desc
ORDER BY net_profit_after_returns DESC
LIMIT 10
