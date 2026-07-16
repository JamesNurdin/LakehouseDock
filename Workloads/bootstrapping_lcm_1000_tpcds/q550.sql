WITH store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month_seq,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month_seq,
        d_closed.d_year AS store_closed_year,
        SUM(ss.ss_net_paid) AS total_store_sales_net_paid,
        SUM(COALESCE(cs.cs_net_paid, 0)) AS total_catalog_sales_net_paid,
        SUM(COALESCE(cs.cs_net_profit, 0)) AS total_catalog_sales_net_profit,
        SUM(COALESCE(cs.cs_ext_discount_amt, 0)) AS total_catalog_discount_amount,
        COUNT(DISTINCT wp_c.wp_web_page_id) AS pages_created,
        COUNT(DISTINCT wp_a.wp_web_page_id) AS pages_accessed
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN web_page wp_c
        ON wp_c.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp_a
        ON wp_a.wp_access_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        d_ship.d_month_seq,
        d_closed.d_year
)
SELECT
    s_store_id,
    s_store_name,
    sold_year,
    sold_month_seq,
    ship_year,
    ship_month_seq,
    store_closed_year,
    total_store_sales_net_paid,
    total_catalog_sales_net_paid,
    total_catalog_sales_net_profit,
    total_catalog_discount_amount,
    pages_created,
    pages_accessed,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_store_sales_net_paid DESC) AS sales_rank
FROM store_metrics
ORDER BY total_store_sales_net_paid DESC, s_store_id
