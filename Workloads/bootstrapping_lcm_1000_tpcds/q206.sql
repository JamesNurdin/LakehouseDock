WITH store_daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_id,
        s.s_city,
        s.s_state,
        d_closure.d_date AS store_closed_date,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        AVG(wp.wp_image_count) AS avg_image_count,
        AVG(wp.wp_link_count) AS avg_link_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closure ON s.s_closed_date_sk = d_closure.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
        AND wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_date, d.d_year, s.s_store_id, s.s_city, s.s_state, d_closure.d_date
)
SELECT
    d_date,
    d_year,
    s_store_id,
    s_city,
    s_state,
    store_closed_date,
    total_sales,
    total_net_paid,
    total_net_profit,
    total_return_amount,
    num_sales,
    num_returns,
    avg_image_count,
    avg_link_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_year
FROM store_daily_agg
WHERE total_sales > 0
ORDER BY profit_rank_year, total_net_profit DESC
LIMIT 100
