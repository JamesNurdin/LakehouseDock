WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        t.t_meal_time,
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS ticket_count
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        t.t_meal_time,
        t.t_hour
),
pages_created AS (
    SELECT
        wp.wp_creation_date_sk AS d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_created
    FROM web_page wp
    GROUP BY wp.wp_creation_date_sk
),
pages_accessed AS (
    SELECT
        wp.wp_access_date_sk AS d_date_sk,
        COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed
    FROM web_page wp
    GROUP BY wp.wp_access_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_manager,
    sa.t_meal_time,
    sa.t_hour,
    sa.total_sales,
    sa.total_quantity,
    sa.avg_price,
    sa.ticket_count,
    COALESCE(pc.pages_created, 0) AS pages_created,
    COALESCE(pa.pages_accessed, 0) AS pages_accessed,
    d_closed.d_date AS store_closed_date
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
LEFT JOIN pages_created pc
    ON d.d_date_sk = pc.d_date_sk
LEFT JOIN pages_accessed pa
    ON d.d_date_sk = pa.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND sa.t_meal_time = 'Lunch'
ORDER BY sa.total_sales DESC
LIMIT 100
