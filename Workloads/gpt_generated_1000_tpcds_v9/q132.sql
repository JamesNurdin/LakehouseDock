WITH joined_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship,
        ws.ws_quantity,
        sm.sm_type,
        sm.sm_carrier,
        p.p_promo_name,
        w.w_city,
        w.w_state
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_promo_sk = p.p_promo_sk
    WHERE sm.sm_carrier = 'AIRBORNE'
      AND p.p_promo_name LIKE '%Holiday%'
      AND w.w_state = 'CA'
      AND cs.cs_coupon_amt > 500
      AND ws.ws_sales_price > 20
),
aggregated AS (
    SELECT
        sm_type,
        w_city,
        p_promo_name,
        SUM(cs_net_paid_inc_ship) AS sum_cs_net_paid,
        SUM(ws_net_paid_inc_ship) AS sum_ws_net_paid,
        COUNT(DISTINCT cs_order_number) AS cs_order_cnt,
        COUNT(DISTINCT ws_order_number) AS ws_order_cnt,
        AVG(cs_coupon_amt) AS avg_coupon_amt,
        MIN(cs_quantity) AS min_cs_quantity,
        MAX(ws_quantity) AS max_ws_quantity,
        SUM(cs_net_paid_inc_ship + ws_net_paid_inc_ship) AS overall_net_paid
    FROM joined_sales
    GROUP BY sm_type, w_city, p_promo_name
)
SELECT
    sm_type,
    w_city,
    p_promo_name,
    sum_cs_net_paid,
    sum_ws_net_paid,
    cs_order_cnt,
    ws_order_cnt,
    avg_coupon_amt,
    min_cs_quantity,
    max_ws_quantity,
    overall_net_paid,
    RANK() OVER (ORDER BY overall_net_paid DESC) AS net_paid_rank
FROM aggregated
ORDER BY overall_net_paid DESC
LIMIT 100
