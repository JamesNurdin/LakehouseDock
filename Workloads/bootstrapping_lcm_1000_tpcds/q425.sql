WITH creation_metrics AS (
    SELECT wp_creation_date_sk AS d_date_sk,
           AVG(wp_image_count) AS avg_image_count_created
    FROM web_page
    GROUP BY wp_creation_date_sk
),
access_metrics AS (
    SELECT wp_access_date_sk AS d_date_sk,
           AVG(wp_link_count) AS avg_link_count_accessed
    FROM web_page
    GROUP BY wp_access_date_sk
),
aggregated AS (
    SELECT
        d_sold.d_year AS sale_year,
        d_sold.d_quarter_name AS sale_quarter,
        d_closed.d_year AS closed_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales_price,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        AVG(cm.avg_image_count_created) AS avg_image_count_created,
        AVG(am.avg_link_count_accessed) AS avg_link_count_accessed,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN creation_metrics cm
        ON cm.d_date_sk = d_sold.d_date_sk
    LEFT JOIN access_metrics am
        ON am.d_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year BETWEEN 2020 AND 2022
      AND s.s_state = 'CA'
    GROUP BY
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_closed.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
)
SELECT
    sale_year,
    sale_quarter,
    closed_year,
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    total_net_profit,
    total_ext_sales_price,
    distinct_customers,
    avg_image_count_created,
    avg_link_count_accessed,
    total_quantity,
    CASE WHEN total_quantity = 0 THEN NULL
         ELSE ROUND(total_net_profit / total_quantity, 2)
    END AS profit_per_item,
    ROW_NUMBER() OVER (PARTITION BY sale_year, sale_quarter ORDER BY total_net_profit DESC) AS store_rank_by_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
