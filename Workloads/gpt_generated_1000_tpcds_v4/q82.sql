WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty,
           MAX(inv_date_sk) AS latest_inv_date_sk
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d_sales.d_year,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name AS call_center,
    cp.cp_department,
    sm.sm_type AS ship_mode_type,
    site.web_name AS website,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    inv_agg.total_qty,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(cs.cs_net_paid) DESC) AS rn_item_by_sales
FROM catalog_sales cs
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
LEFT JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
LEFT JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
LEFT JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
LEFT JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d_sales.d_year = 2001
GROUP BY
    d_sales.d_year,
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    site.web_name,
    inv_agg.total_qty
ORDER BY total_net_paid DESC
LIMIT 100
