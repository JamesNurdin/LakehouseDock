WITH base AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_manager,
        cc.cc_tax_percentage,
        dc_closed.d_date AS closure_date,
        dc_closed.d_day_name AS closure_day_name,
        dc_closed.d_month_seq AS closure_month_seq,
        dc_closed.d_quarter_name AS closure_quarter,
        dc_open.d_year AS open_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        i.inv_warehouse_sk,
        i.inv_quantity_on_hand,
        wp.wp_web_page_id,
        wp.wp_char_count,
        dw_access.d_day_name AS wp_access_day_name
    FROM call_center cc
    JOIN date_dim dc_closed ON cc.cc_closed_date_sk = dc_closed.d_date_sk
    JOIN date_dim dc_open ON cc.cc_open_date_sk = dc_open.d_date_sk
    JOIN store s ON s.s_closed_date_sk = dc_closed.d_date_sk
    JOIN inventory i ON i.inv_date_sk = dc_closed.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = dc_closed.d_date_sk
    JOIN date_dim dw_access ON wp.wp_access_date_sk = dw_access.d_date_sk
),
aggregated AS (
    SELECT
        cc_call_center_id,
        cc_name,
        cc_manager,
        cc_tax_percentage,
        open_year,
        closure_date,
        closure_day_name,
        closure_month_seq,
        closure_quarter,
        s_store_id,
        s_store_name,
        s_city,
        s_state,
        s_floor_space,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT wp_web_page_id) AS distinct_pages_created,
        AVG(wp_char_count) AS avg_page_char_count,
        MAX(wp_char_count) AS max_page_char_count
    FROM base
    GROUP BY
        cc_call_center_id,
        cc_name,
        cc_manager,
        cc_tax_percentage,
        open_year,
        closure_date,
        closure_day_name,
        closure_month_seq,
        closure_quarter,
        s_store_id,
        s_store_name,
        s_city,
        s_state,
        s_floor_space,
        inv_warehouse_sk
)
SELECT
    cc_call_center_id,
    cc_name,
    cc_manager,
    cc_tax_percentage,
    open_year,
    closure_date,
    closure_day_name,
    closure_month_seq,
    closure_quarter,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    s_floor_space,
    inv_warehouse_sk,
    total_quantity_on_hand,
    distinct_pages_created,
    avg_page_char_count,
    max_page_char_count,
    CASE
        WHEN total_quantity_on_hand > 1000 THEN 'HIGH'
        WHEN total_quantity_on_hand BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS inventory_level_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_quantity_on_hand DESC) AS inventory_rank_by_store
FROM aggregated
ORDER BY total_quantity_on_hand DESC
LIMIT 100
