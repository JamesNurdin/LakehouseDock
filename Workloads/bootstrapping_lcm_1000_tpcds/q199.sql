WITH base AS (
    SELECT
        d.d_year,
        d.d_current_month,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_date AS store_closed_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_page_count
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY d.d_year, d.d_current_month, s.s_store_id, s.s_store_name, s.s_state, d_closed.d_date
)
SELECT
    b.d_year,
    b.d_current_month,
    b.s_store_id,
    b.s_store_name,
    b.s_state,
    b.store_closed_date,
    b.total_sales,
    b.total_profit,
    b.total_inventory,
    b.distinct_page_count,
    ROW_NUMBER() OVER (PARTITION BY b.d_year, b.d_current_month ORDER BY b.total_sales DESC) AS sales_rank
FROM base b
WHERE b.total_sales > 0
ORDER BY b.d_year, b.d_current_month, sales_rank
LIMIT 100
