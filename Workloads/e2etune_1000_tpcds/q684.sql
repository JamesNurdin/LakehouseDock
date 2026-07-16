WITH warehouse_inventory AS (
    SELECT
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM warehouse w
    JOIN inventory i
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT
    w.w_country AS warehouse_country,
    hd.hd_buy_potential,
    sm.sm_type AS ship_mode,
    p.p_promo_name,
    COUNT(*) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    wi.total_inventory_on_hand,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse_inventory wi
    ON w.w_warehouse_sk = wi.w_warehouse_sk
WHERE cs.cs_quantity > 20
  AND cs.cs_sold_date_sk BETWEEN 2458848 AND 2458912
  AND p.p_channel_email = 'Y'
  AND p.p_cost > 1000
GROUP BY
    w.w_country,
    hd.hd_buy_potential,
    sm.sm_type,
    p.p_promo_name,
    wi.total_inventory_on_hand
ORDER BY total_net_profit DESC
LIMIT 10
