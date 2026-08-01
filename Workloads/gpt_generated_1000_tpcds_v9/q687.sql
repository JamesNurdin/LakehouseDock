WITH cs AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM catalog_sales cs
),
cr AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_net_loss,
        cr.cr_reason_sk
    FROM catalog_returns cr
),
ss AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_profit
    FROM store_sales ss
),
ws AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM web_sales ws
),
inv AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_date_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    cd.cd_gender,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_catalog_net_profit,
    AVG(cs.cs_quantity) AS avg_catalog_quantity_per_order
FROM cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN cr
    ON cs.cs_order_number = cr.cr_order_number
   AND cs.cs_item_sk = cr.cr_item_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ss
    ON ss.ss_item_sk = i.i_item_sk
   AND ss.ss_sold_date_sk = d.d_date_sk
JOIN ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_date_sk = d.d_date_sk
JOIN inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 2000
  AND i.i_current_price BETWEEN 10 AND 1000
  AND cc.cc_gmt_offset >= -5.0
GROUP BY i.i_item_id,
         i.i_product_name,
         d.d_year,
         d.d_month_seq,
         cc.cc_name,
         sm.sm_type,
         w.w_warehouse_name,
         cd.cd_gender
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_catalog_net_profit DESC
LIMIT 100
