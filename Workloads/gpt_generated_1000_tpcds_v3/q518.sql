WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amt,
        SUM(cr_net_loss) AS total_net_loss
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_item_sk, cr_reason_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_promo_sk,
        SUM(ws_quantity) AS total_sales_qty,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_quantity > 0
    GROUP BY ws_item_sk, ws_promo_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_brand,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name,
    sm.sm_carrier,
    r.r_reason_desc,
    p.p_promo_name,
    cr_agg.total_return_qty,
    cr_agg.total_return_amt,
    ws_agg.total_sales_qty,
    ws_agg.total_net_paid,
    ws_agg.total_net_profit,
    (ws_agg.total_net_profit - cr_agg.total_net_loss) AS net_profit_adjusted
FROM cr_agg
JOIN catalog_returns cr
    ON cr.cr_item_sk = cr_agg.cr_item_sk
   AND cr.cr_reason_sk = cr_agg.cr_reason_sk
JOIN item i
    ON i.i_item_sk = cr.cr_item_sk
JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN customer c_ref
    ON c_ref.c_customer_sk = cr.cr_refunded_customer_sk
JOIN customer_address ca
    ON ca.ca_address_sk = cr.cr_refunded_addr_sk
JOIN ws_agg
    ON ws_agg.ws_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_promo_sk = ws_agg.ws_promo_sk
JOIN promotion p
    ON p.p_promo_sk = ws.ws_promo_sk
   AND p.p_item_sk = i.i_item_sk
WHERE
    i.i_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_state = 'CA'
    AND w.w_city = 'Salem'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY net_profit_adjusted DESC
LIMIT 100
