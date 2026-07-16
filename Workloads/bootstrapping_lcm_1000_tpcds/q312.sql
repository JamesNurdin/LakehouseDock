WITH inventory_by_date AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        d.d_date AS inv_date,
        d.d_year
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
promotion_periods AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_cost,
        start_d.d_date AS start_date,
        end_d.d_date AS end_date,
        p.p_discount_active,
        p.p_channel_tv
    FROM promotion p
    JOIN date_dim start_d ON p.p_start_date_sk = start_d.d_date_sk
    JOIN date_dim end_d ON p.p_end_date_sk = end_d.d_date_sk
),
store_closed AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        closed_d.d_date AS closed_date,
        s.s_floor_space
    FROM store s
    JOIN date_dim closed_d ON s.s_closed_date_sk = closed_d.d_date_sk
)
SELECT
    agg.p_promo_name,
    agg.start_date,
    agg.end_date,
    agg.s_store_name,
    agg.s_city,
    agg.s_state,
    agg.w_warehouse_name,
    agg.w_city,
    agg.w_state,
    agg.total_quantity,
    agg.distinct_items,
    agg.avg_promo_cost,
    agg.discounted_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.p_promo_sk ORDER BY agg.total_quantity DESC) AS promo_rank_by_quantity
FROM (
    SELECT
        pp.p_promo_sk,
        pp.p_promo_name,
        pp.start_date,
        pp.end_date,
        sc.s_store_name,
        sc.s_city,
        sc.s_state,
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        SUM(ib.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT ib.inv_item_sk) AS distinct_items,
        AVG(pp.p_cost) AS avg_promo_cost,
        SUM(CASE WHEN pp.p_discount_active = 'Y' THEN ib.inv_quantity_on_hand ELSE 0 END) AS discounted_quantity
    FROM inventory_by_date ib
    JOIN promotion_periods pp
        ON ib.inv_date BETWEEN pp.start_date AND pp.end_date
    JOIN warehouse w
        ON ib.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_closed sc
        ON w.w_state = sc.s_state
    WHERE sc.s_floor_space > 10000
      AND ib.d_year = 2022
    GROUP BY
        pp.p_promo_sk,
        pp.p_promo_name,
        pp.start_date,
        pp.end_date,
        sc.s_store_name,
        sc.s_city,
        sc.s_state,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
) agg
ORDER BY agg.total_quantity DESC
LIMIT 100
