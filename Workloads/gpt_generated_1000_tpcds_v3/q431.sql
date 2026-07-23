/* Goal: Analyze total catalog sales and profit by item, promotion, and channel, enriched with inventory levels, store and web returns, and related dimensions. */
WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    t.t_hour,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    cc.cc_name AS call_center_name,
    cp.cp_department AS catalog_department,
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    cd_bill.cd_gender AS bill_gender,
    cd_ship.cd_gender AS ship_gender,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COALESCE(inv_agg.total_qty_on_hand, 0) AS total_inventory_on_hand,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_sales_price
FROM catalog_sales cs
INNER JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
INNER JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN inventory_agg inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
    AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
    AND ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r_sr
    ON r_sr.r_reason_sk = sr.sr_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
LEFT JOIN reason r_wr
    ON r_wr.r_reason_sk = wr.wr_reason_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    cs.cs_sold_date_sk BETWEEN 2450885 AND 2451015
    AND p.p_discount_active = 'Y'
    AND EXISTS (SELECT 1 FROM store_returns sr2 WHERE sr2.sr_item_sk = i.i_item_sk)
GROUP BY
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    t.t_hour,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    cd_bill.cd_gender,
    cd_ship.cd_gender,
    inv_agg.total_qty_on_hand
HAVING
    SUM(cs.cs_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
