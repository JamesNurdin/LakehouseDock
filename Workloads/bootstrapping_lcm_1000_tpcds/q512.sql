WITH agg AS (
    SELECT
        d_sales.d_year,
        d_sales.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        COALESCE(d_closed.d_year, -1) AS store_closed_year,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss,
        COALESCE(SUM(wc.wp_image_count), 0) AS total_images_created,
        COALESCE(SUM(wa.wp_image_count), 0) AS total_images_accessed,
        COUNT(DISTINCT wc.wp_web_page_id) AS distinct_pages_created,
        COUNT(DISTINCT wa.wp_web_page_id) AS distinct_pages_accessed
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_returned_date_sk = d_sales.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN web_page wc
        ON wc.wp_creation_date_sk = d_sales.d_date_sk
    LEFT JOIN web_page wa
        ON wa.wp_access_date_sk = d_sales.d_date_sk
    GROUP BY
        d_sales.d_year,
        d_sales.d_quarter_name,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_year
)
SELECT
    d_year,
    d_quarter_name,
    s_store_id,
    s_store_name,
    s_state,
    store_closed_year,
    num_transactions,
    total_sales,
    total_profit,
    total_return_amount,
    total_return_loss,
    total_images_created,
    total_images_accessed,
    distinct_pages_created,
    distinct_pages_accessed,
    ROW_NUMBER() OVER (
        PARTITION BY d_year, d_quarter_name
        ORDER BY (total_profit - total_return_loss) DESC
    ) AS profit_rank
FROM agg
ORDER BY d_year, d_quarter_name, profit_rank
LIMIT 100
