SELECT
    cp.cp_catalog_page_id,
    i.i_brand,
    w.w_state,
    hd.hd_buy_potential,
    CASE WHEN i.i_current_price > 200 THEN 'High' ELSE 'Low' END AS price_category,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_net_profit + ws.ws_net_profit) AS total_net_profit
FROM
    catalog_sales cs
JOIN
    catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN
    item i ON cs.cs_item_sk = i.i_item_sk
JOIN
    household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN
    warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN
    store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN
    web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN
    web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN
    inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    cp.cp_type = 'quarterly'
    AND i.i_current_price > 150
    AND w.w_state = 'CA'
    AND inv.inv_quantity_on_hand > 0
    AND cs.cs_ext_tax > 10
    AND sr.sr_return_quantity > 1
GROUP BY
    cp.cp_catalog_page_id,
    i.i_brand,
    w.w_state,
    hd.hd_buy_potential,
    CASE WHEN i.i_current_price > 200 THEN 'High' ELSE 'Low' END
ORDER BY
    total_net_profit DESC
LIMIT 100
