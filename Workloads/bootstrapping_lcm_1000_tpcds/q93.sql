WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk AS store_sk,
            ss.ss_sold_date_sk AS sold_date_sk,
            dd.d_year,
            dd.d_quarter_seq,
            t.t_hour,
            SUM(ss.ss_net_profit) AS total_net_profit,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            COUNT(*) AS sales_cnt,
            AVG(ss.ss_sales_price) AS avg_sales_price
        FROM store_sales ss
        JOIN date_dim dd
            ON ss.ss_sold_date_sk = dd.d_date_sk
        JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        GROUP BY
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            dd.d_year,
            dd.d_quarter_seq,
            t.t_hour
    ),
    web_page_creation_agg AS (
        SELECT
            dd_creation.d_date_sk AS date_sk,
            COUNT(*) AS pages_created,
            SUM(wp.wp_image_count) AS total_images_created
        FROM web_page wp
        JOIN date_dim dd_creation
            ON wp.wp_creation_date_sk = dd_creation.d_date_sk
        GROUP BY dd_creation.d_date_sk
    ),
    web_page_access_agg AS (
        SELECT
            dd_access.d_date_sk AS date_sk,
            COUNT(*) AS pages_accessed,
            SUM(wp.wp_link_count) AS total_links_accessed
        FROM web_page wp
        JOIN date_dim dd_access
            ON wp.wp_access_date_sk = dd_access.d_date_sk
        GROUP BY dd_access.d_date_sk
    ),
    store_quarter_profit AS (
        SELECT
            s.s_store_id,
            sa.d_year,
            sa.d_quarter_seq,
            SUM(sa.total_net_profit) AS quarter_net_profit,
            RANK() OVER (
                PARTITION BY sa.d_year, sa.d_quarter_seq
                ORDER BY SUM(sa.total_net_profit) DESC
            ) AS profit_rank
        FROM sales_agg sa
        JOIN store s
            ON sa.store_sk = s.s_store_sk
        GROUP BY
            s.s_store_id,
            sa.d_year,
            sa.d_quarter_seq
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    sa.d_year,
    sa.d_quarter_seq,
    sa.t_hour,
    sa.sales_cnt,
    ROUND(sa.total_sales, 2) AS total_sales,
    ROUND(sa.total_net_profit, 2) AS total_net_profit,
    ROUND(sa.avg_sales_price, 2) AS avg_sales_price,
    COALESCE(wc.pages_created, 0) AS pages_created,
    COALESCE(wc.total_images_created, 0) AS total_images_created,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed,
    COALESCE(wa.total_links_accessed, 0) AS total_links_accessed,
    CASE WHEN dc.d_date_sk IS NOT NULL THEN 'Closed' ELSE 'Open' END AS store_status,
    CASE WHEN sa.sales_cnt > 0
        THEN ROUND(COALESCE(wc.pages_created, 0) * 1.0 / sa.sales_cnt, 4)
        ELSE 0
    END AS pages_created_per_sale,
    CASE WHEN sa.sales_cnt > 0
        THEN ROUND(sa.total_net_profit / sa.sales_cnt, 4)
        ELSE 0
    END AS profit_per_sale,
    sq.quarter_net_profit,
    sq.profit_rank
FROM sales_agg sa
JOIN store s
    ON sa.store_sk = s.s_store_sk
LEFT JOIN date_dim dc
    ON s.s_closed_date_sk = dc.d_date_sk
LEFT JOIN web_page_creation_agg wc
    ON sa.sold_date_sk = wc.date_sk
LEFT JOIN web_page_access_agg wa
    ON sa.sold_date_sk = wa.date_sk
LEFT JOIN store_quarter_profit sq
    ON s.s_store_id = sq.s_store_id
    AND sa.d_year = sq.d_year
    AND sa.d_quarter_seq = sq.d_quarter_seq
ORDER BY
    s.s_store_id,
    sa.d_year,
    sa.d_quarter_seq,
    sa.t_hour
