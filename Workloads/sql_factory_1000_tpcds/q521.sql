SELECT
    hd.hd_demo_sk,
    w.w_warehouse_name,
    SUM(cs.cs_quantity) AS total_sales_qty,
    COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_qty,
    CASE
        WHEN SUM(cs.cs_quantity) = 0 THEN 0
        ELSE COALESCE(SUM(cr.cr_return_quantity), 0) / SUM(cs.cs_quantity)
    END AS return_rate,
    CASE
        WHEN COALESCE(SUM(cr.cr_return_quantity), 0) / NULLIF(SUM(cs.cs_quantity), 0) > 0.2 THEN 'High'
        ELSE 'Low'
    END AS return_category,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(cr.cr_return_quantity), 0) / NULLIF(SUM(cs.cs_quantity), 0) DESC) AS return_rate_rank
FROM household_demographics hd
JOIN catalog_sales cs
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
GROUP BY hd.hd_demo_sk, w.w_warehouse_name
