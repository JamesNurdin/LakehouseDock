WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_year AS sales_year,
        d_closed.d_year AS store_closed_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_ext_sales_price), 0) AS profit_margin,
        COUNT(DISTINCT ss.ss_customer_sk) AS unique_customers,
        COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
        SUM(wp.wp_image_count) AS total_images
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_closed.d_date_sk
    WHERE d_sales.d_year = 2002
      AND cd.cd_gender = 'F'
      AND s.s_state = 'CA'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        d_sales.d_year,
        d_closed.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
)
SELECT
    s_store_name,
    sales_year,
    store_closed_year,
    cd_gender,
    cd_marital_status,
    cd_credit_rating,
    CASE WHEN cd_credit_rating = 'A' THEN 'High' ELSE 'Low' END AS credit_category,
    total_sales,
    avg_profit,
    profit_margin,
    unique_customers,
    distinct_pages,
    total_images,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
