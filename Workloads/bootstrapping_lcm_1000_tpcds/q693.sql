WITH
    sales_agg AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_sold_date_sk,
            SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
            SUM(ss.ss_net_profit) AS total_net_profit
        FROM store_sales ss
        GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
    ),
    returns_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk
    ),
    web_page_creation_agg AS (
        SELECT
            wp.wp_creation_date_sk,
            COUNT(DISTINCT wp.wp_web_page_id) AS pages_created
        FROM web_page wp
        GROUP BY wp.wp_creation_date_sk
    ),
    web_page_access_agg AS (
        SELECT
            wp.wp_access_date_sk,
            COUNT(DISTINCT wp.wp_web_page_id) AS pages_accessed
        FROM web_page wp
        GROUP BY wp.wp_access_date_sk
    )
SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_date AS sales_date,
    d_store_closed.d_date AS store_closed_date,
    sa.total_sales_amount,
    sa.total_net_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(wc.pages_created, 0) AS pages_created_on_sales_date,
    COALESCE(wa.pages_accessed, 0) AS pages_accessed_on_sales_date,
    RANK() OVER (ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) DESC) AS profit_rank
FROM sales_agg sa
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN returns_agg ra
    ON ra.cr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN web_page_creation_agg wc
    ON wc.wp_creation_date_sk = d_sales.d_date_sk
LEFT JOIN web_page_access_agg wa
    ON wa.wp_access_date_sk = d_sales.d_date_sk
ORDER BY profit_rank
LIMIT 100
