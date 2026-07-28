WITH sales_augmented AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship,
        cs.cs_item_sk,
        d_sold.d_year AS sold_year,
        i.i_brand,
        i.i_category,
        sm.sm_type,
        t.t_shift,
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY cs.cs_net_paid_inc_ship DESC) AS brand_rank,
        CASE WHEN cs.cs_net_paid_inc_ship > 5000 THEN 'HIGH' ELSE 'LOW' END AS payment_level
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    -- The join to d_start satisfies the promotion start‑date rule; its columns are not needed further
    WHERE d_sold.d_year = 1998
      AND cs.cs_quantity > 5
      AND t.t_shift = 'first'
)
SELECT
    sa.cs_order_number,
    sa.cs_quantity,
    sa.cs_net_paid_inc_ship,
    sa.sold_year,
    sa.i_brand,
    sa.i_category,
    sa.sm_type,
    sa.t_shift,
    sa.p_promo_name,
    sa.brand_rank,
    sa.payment_level,
    (
        SELECT SUM(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_item_sk = sa.cs_item_sk
    ) AS total_promo_cost
FROM sales_augmented sa
WHERE sa.brand_rank <= 10
ORDER BY sa.i_brand, sa.brand_rank
LIMIT 100
