WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name AS call_center_name,
    r.r_reason_desc,
    wp.wp_url,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
    (SUM(cs.cs_net_paid) - SUM(cr.cr_return_amt_inc_tax) - SUM(sr.sr_return_amt_inc_tax) - SUM(wr.wr_return_amt_inc_tax)) AS net_profit_estimate,
    SUM(inv_agg.total_qty_on_hand) AS total_inventory_qty
FROM inv_agg
JOIN item i ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_order_number = cs.cs_order_number
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    cc.cc_state = 'CA'
    AND r.r_reason_desc LIKE '%warranty%'
    AND i.i_rec_start_date >= DATE '1999-01-01'
    AND wp.wp_max_ad_count = 2
GROUP BY
    i.i_item_id,
    i.i_product_name,
    w.w_warehouse_name,
    cc.cc_name,
    r.r_reason_desc,
    wp.wp_url
ORDER BY net_profit_estimate DESC
LIMIT 100
