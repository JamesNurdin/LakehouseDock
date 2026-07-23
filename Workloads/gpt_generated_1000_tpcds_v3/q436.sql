WITH sales_cte AS (
    SELECT DISTINCT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_item_sk,
        d_sold.d_date AS sold_date,
        d_sold.d_year,
        d_ship.d_date AS ship_date,
        t.t_hour,
        t.t_sub_shift,
        sm.sm_type,
        sm.sm_carrier,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_catalog,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND t.t_hour BETWEEN 9 AND 17
      AND sm.sm_type = 'AIR'
      AND p.p_channel_catalog = 'N'
      AND inv.inv_quantity_on_hand > 0
      AND cs.cs_quantity > 1
)
SELECT
    cs_order_number,
    sold_date,
    ship_date,
    d_year,
    t_hour,
    t_sub_shift,
    sm_type,
    sm_carrier,
    p_promo_id,
    p_promo_name,
    cs_net_profit,
    cs_quantity,
    inv_quantity_on_hand,
    CASE WHEN cs_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS order_type,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY cs_net_profit DESC) AS profit_rank
FROM sales_cte
ORDER BY profit_rank, cs_net_profit DESC
LIMIT 100
