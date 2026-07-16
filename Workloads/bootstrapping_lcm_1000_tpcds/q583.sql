WITH sales_summary AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sale.d_current_quarter,
        d_sale.d_year,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(wp.wp_link_count) AS total_page_links,
        SUM(wp.wp_image_count) AS total_page_images,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        CASE
            WHEN d_closed.d_date IS NOT NULL THEN 'Closed_' || CAST(d_closed.d_year AS VARCHAR)
            ELSE 'Open'
        END AS store_closed_status
    FROM store_sales ss
    JOIN date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d_sale.d_date_sk
    LEFT JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sale.d_year = 2022
      AND s.s_state = 'CA'
      AND (d_access.d_weekend = 'Y' OR d_access.d_weekend IS NULL)
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sale.d_current_quarter,
        d_sale.d_year,
        d_closed.d_date,
        d_closed.d_year
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    s_store_id,
    s_store_name,
    d_current_quarter,
    d_year,
    total_net_profit,
    total_sales,
    avg_sales_price,
    distinct_tickets,
    total_page_links,
    total_page_images,
    distinct_pages,
    store_closed_status,
    ROW_NUMBER() OVER (PARTITION BY d_current_quarter ORDER BY total_net_profit DESC) AS profit_rank_in_quarter
FROM sales_summary
ORDER BY d_current_quarter, total_net_profit DESC
LIMIT 100
