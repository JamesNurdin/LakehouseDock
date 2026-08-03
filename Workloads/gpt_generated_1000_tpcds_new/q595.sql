WITH base_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       ws.ws_ext_list_price,
       ws.ws_coupon_amt,
       ws.ws_net_profit,
       w.w_warehouse_sk,
       w.w_state,
       w.w_country,
       p.p_promo_id,
       p.p_discount_active,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       cc.cc_division_name,
       r.r_reason_desc
   FROM web_sales ws
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN catalog_returns cr ON w.w_warehouse_sk = cr.cr_warehouse_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE ws.ws_ext_list_price > 1000
     AND ws.ws_coupon_amt < 2000
     AND w.w_state = 'CA'
     AND p.p_discount_active = 'Y'
     AND cc.cc_division_name LIKE 'pri%'
     AND r.r_reason_desc LIKE '%size%'
)
SELECT
    ws_order_number,
    ws_sold_date_sk,
    ws_ext_list_price,
    ws_coupon_amt,
    ws_net_profit,
    p_promo_id,
    profit_rank,
    profit_flag,
    total_return_amount,
    cr_return_quantity,
    cc_division_name,
    r_reason_desc
FROM (
    SELECT
        bd.ws_order_number,
        bd.ws_sold_date_sk,
        bd.ws_ext_list_price,
        bd.ws_coupon_amt,
        bd.ws_net_profit,
        bd.p_promo_id,
        RANK() OVER (PARTITION BY bd.p_promo_id ORDER BY bd.ws_net_profit DESC) AS profit_rank,
        CASE WHEN bd.ws_net_profit > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag,
        lr.total_return_amount,
        bd.cr_return_quantity,
        bd.cc_division_name,
        bd.r_reason_desc
    FROM base_data bd
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = bd.w_warehouse_sk
    ) lr
    WHERE bd.cr_return_quantity > 1

    UNION

    SELECT
        bd.ws_order_number,
        bd.ws_sold_date_sk,
        bd.ws_ext_list_price,
        bd.ws_coupon_amt,
        bd.ws_net_profit,
        bd.p_promo_id,
        RANK() OVER (PARTITION BY bd.p_promo_id ORDER BY bd.ws_net_profit DESC) AS profit_rank,
        CASE WHEN bd.ws_net_profit > 0 THEN 'Positive' ELSE 'Non-positive' END AS profit_flag,
        lr.total_return_amount,
        bd.cr_return_quantity,
        bd.cc_division_name,
        bd.r_reason_desc
    FROM base_data bd
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = bd.w_warehouse_sk
    ) lr
    WHERE bd.cr_return_quantity = 1
) q
ORDER BY profit_rank ASC, ws_net_profit DESC
OFFSET 0 LIMIT 100
