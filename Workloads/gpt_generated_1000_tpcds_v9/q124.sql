WITH filtered_dates AS (
    SELECT d_date_sk, d_year
    FROM tpcds.date_dim
    WHERE d_year = 2001
)
SELECT year, category, channel, total_net_paid, transaction_count
FROM (
    SELECT
        fd.d_year AS year,
        i.i_category AS category,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count
    FROM tpcds.store_sales AS ss
    JOIN filtered_dates AS fd ON ss.ss_sold_date_sk = fd.d_date_sk
    JOIN tpcds.item AS i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion AS p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY fd.d_year, i.i_category
    UNION ALL
    SELECT
        fd.d_year AS year,
        i.i_category AS category,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS transaction_count
    FROM tpcds.web_sales AS ws
    JOIN filtered_dates AS fd ON ws.ws_sold_date_sk = fd.d_date_sk
    JOIN tpcds.item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'home'
    GROUP BY fd.d_year, i.i_category
) AS combined
ORDER BY year, category, channel
