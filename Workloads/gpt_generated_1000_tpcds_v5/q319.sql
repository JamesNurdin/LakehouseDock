WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_dow,
        i.inv_quantity_on_hand,
        i.inv_item_sk,
        s.s_store_name,
        s.s_floor_space,
        p.p_discount_active,
        p.p_cost,
        wp.wp_type,
        wp.wp_char_count
    FROM tpcds.date_dim d
    JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON p.p_start_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 1900
      AND d.d_month_seq BETWEEN 1 AND 12
      AND s.s_floor_space > 5000000
      AND i.inv_quantity_on_hand > 0
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'Content'
),
agg AS (
    SELECT
        d_year,
        s_store_name,
        SUM(inv_quantity_on_hand) AS total_qty,
        AVG(p_cost) AS avg_promo_cost,
        SUM(wp_char_count) AS total_char_count,
        CASE WHEN MAX(s_floor_space) > 8000000 THEN 'Large' ELSE 'Medium' END AS store_size_category
    FROM joined
    GROUP BY ROLLUP(d_year, s_store_name)
)
SELECT
    d_year,
    s_store_name,
    total_qty,
    avg_promo_cost,
    total_char_count,
    store_size_category,
    CASE WHEN total_qty > (
            SELECT AVG(total_qty) FROM agg WHERE d_year IS NOT NULL
        ) THEN 'Above Avg' ELSE 'Below Avg' END AS qty_vs_avg
FROM agg
WHERE (d_year IS NOT NULL AND s_store_name IS NOT NULL)
  AND total_qty > 1000
ORDER BY d_year ASC NULLS LAST, s_store_name ASC NULLS LAST
