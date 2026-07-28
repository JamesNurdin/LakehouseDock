WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        SUM(cs_net_paid) AS sum_cs_net_paid,
        SUM(cs_net_profit) AS sum_cs_net_profit,
        COUNT(*) AS cnt_cs_orders,
        MIN(cs_sold_date_sk) AS min_cs_sold_date,
        MAX(cs_sold_date_sk) AS max_cs_sold_date
    FROM catalog_sales
    WHERE cs_quantity > 0
    GROUP BY cs_item_sk, cs_warehouse_sk, cs_call_center_sk, cs_catalog_page_sk, cs_promo_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_warehouse_sk,
        ws_promo_sk,
        SUM(ws_net_paid) AS sum_ws_net_paid,
        SUM(ws_net_profit) AS sum_ws_net_profit,
        COUNT(*) AS cnt_ws_orders
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk, ws_warehouse_sk, ws_promo_sk
),
inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
cr_agg AS (
    SELECT
        cr_item_sk,
        cr_warehouse_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS sum_return_amount,
        SUM(cr_net_loss) AS sum_net_loss,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_warehouse_sk, cr_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cp.cp_catalog_page_number,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    w.w_warehouse_name,
    cs_agg.sum_cs_net_paid,
    ws_agg.sum_ws_net_paid,
    inv_agg.total_on_hand,
    cr_agg.sum_return_amount,
    cs_agg.sum_cs_net_profit,
    ws_agg.sum_ws_net_profit,
    cs_agg.cnt_cs_orders,
    ws_agg.cnt_ws_orders,
    cr_agg.cnt_returns,
    (cs_agg.sum_cs_net_paid + COALESCE(ws_agg.sum_ws_net_paid, 0) - COALESCE(cr_agg.sum_return_amount, 0)) AS net_total,
    RANK() OVER (PARTITION BY cc.cc_state ORDER BY (cs_agg.sum_cs_net_paid + COALESCE(ws_agg.sum_ws_net_paid, 0) - COALESCE(cr_agg.sum_return_amount, 0)) DESC) AS state_rank
FROM cs_agg
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
LEFT JOIN ws_agg
    ON ws_agg.ws_item_sk = i.i_item_sk
   AND ws_agg.ws_warehouse_sk = w.w_warehouse_sk
   AND ws_agg.ws_promo_sk = p.p_promo_sk
LEFT JOIN inv_agg
    ON inv_agg.inv_item_sk = i.i_item_sk
   AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN cr_agg
    ON cr_agg.cr_item_sk = i.i_item_sk
   AND cr_agg.cr_warehouse_sk = w.w_warehouse_sk
   AND cr_agg.cr_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_catalog_page_number IN (8, 13)
  AND i.i_brand = 'Brand#12'
  AND p.p_discount_active = 'Y'
ORDER BY net_total DESC
LIMIT 100
