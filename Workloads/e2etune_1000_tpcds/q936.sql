WITH wp_metrics AS (
    SELECT
        wp_customer_sk AS customer_sk,
        SUM(wp_image_count) AS total_images,
        SUM(wp_link_count) AS total_links,
        COUNT(*) AS page_views
    FROM web_page
    GROUP BY wp_customer_sk
),
sales_agg AS (
    SELECT
        ss.ss_customer_sk AS customer_sk,
        t.t_hour AS hour_of_day,
        cd.cd_gender AS gender,
        COUNT(*) AS num_transactions,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 21
      AND c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY ss.ss_customer_sk, t.t_hour, cd.cd_gender
)
SELECT
    s.customer_sk,
    c.c_first_name,
    c.c_last_name,
    s.hour_of_day,
    s.gender,
    s.num_transactions,
    s.total_net_paid,
    s.total_profit,
    s.total_discount,
    wp.total_images,
    wp.total_links,
    wp.page_views,
    RANK() OVER (PARTITION BY s.hour_of_day, s.gender ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
JOIN customer c ON s.customer_sk = c.c_customer_sk
LEFT JOIN wp_metrics wp ON s.customer_sk = wp.customer_sk
WHERE s.total_profit > 1000
ORDER BY s.hour_of_day, s.gender, profit_rank
LIMIT 50
