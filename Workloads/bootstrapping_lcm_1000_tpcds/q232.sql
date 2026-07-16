WITH inv_date AS (
    SELECT i.inv_item_sk,
           i.inv_quantity_on_hand,
           i.inv_date_sk,
           i.inv_warehouse_sk,
           d.d_date,
           d.d_year
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
store_dates AS (
    SELECT s.s_store_sk,
           s.s_store_name,
           s.s_city,
           s.s_state,
           d.d_date AS closed_date,
           d.d_year AS closed_year
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
),
promo_start AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_start_date_sk,
           d.d_date AS start_date,
           d.d_year AS start_year,
           p.p_discount_active
    FROM promotion p
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
),
promo_end AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           p.p_end_date_sk,
           d.d_date AS end_date,
           d.d_year AS end_year,
           p.p_discount_active
    FROM promotion p
    JOIN date_dim d ON p.p_end_date_sk = d.d_date_sk
)
SELECT
    agg.w_warehouse_name,
    agg.w_city,
    agg.w_state,
    agg.s_store_name,
    agg.s_city,
    agg.s_state,
    agg.inventory_date,
    agg.closed_date,
    agg.start_promo,
    agg.end_promo,
    agg.inv_item_sk,
    agg.total_quantity,
    ROW_NUMBER() OVER (ORDER BY agg.total_quantity DESC) AS quantity_rank
FROM (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        sd.s_store_name,
        sd.s_city,
        sd.s_state,
        inv.d_date AS inventory_date,
        sd.closed_date,
        ps.p_promo_name AS start_promo,
        pe.p_promo_name AS end_promo,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inv_date inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_dates sd ON sd.closed_year = inv.d_year
    LEFT JOIN promo_start ps ON ps.p_start_date_sk = inv.inv_date_sk
    LEFT JOIN promo_end pe ON pe.p_end_date_sk = inv.inv_date_sk
    GROUP BY
        w.w_warehouse_name,
        w.w_city,
        w.w_state,
        sd.s_store_name,
        sd.s_city,
        sd.s_state,
        inv.d_date,
        sd.closed_date,
        ps.p_promo_name,
        pe.p_promo_name,
        inv.inv_item_sk
) agg
ORDER BY quantity_rank
LIMIT 50
