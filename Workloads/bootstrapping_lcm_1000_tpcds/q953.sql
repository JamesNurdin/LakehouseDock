WITH daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_city,
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        d_end.d_date AS promo_end_date,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        MAX(p.p_response_target) AS max_response_target
    FROM date_dim d
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d.d_year = 2022
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        w.w_warehouse_name,
        w.w_city,
        s.s_store_name,
        s.s_city,
        p.p_promo_name,
        p.p_cost,
        p.p_discount_active,
        d_end.d_date
)
SELECT
    da.d_date,
    da.d_year,
    da.d_month_seq,
    da.w_warehouse_name,
    da.w_city,
    da.s_store_name,
    da.s_city,
    da.p_promo_name,
    da.p_cost,
    da.p_discount_active,
    da.promo_end_date,
    da.total_qty,
    da.distinct_items,
    da.max_response_target,
    AVG(da.p_cost) OVER (PARTITION BY da.w_warehouse_name ORDER BY da.d_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS avg_30d_promo_cost,
    SUM(da.total_qty) OVER (PARTITION BY da.w_warehouse_name ORDER BY da.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_7_day_qty,
    CASE WHEN da.p_discount_active = 'Y' THEN da.total_qty ELSE 0 END AS discounted_qty,
    CASE WHEN da.total_qty > 0 THEN
        (CASE WHEN da.p_discount_active = 'Y' THEN da.total_qty ELSE 0 END) * 1.0 / da.total_qty
    ELSE 0 END AS discount_ratio
FROM daily_agg da
WHERE da.total_qty > 0
ORDER BY da.total_qty DESC
LIMIT 100
