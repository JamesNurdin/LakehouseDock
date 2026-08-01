WITH agg_sales AS (
    SELECT
        s.s_state,
        p.p_promo_name,
        s.s_store_sk,
        MIN(s.s_store_id) AS store_id_sample,
        SUM(ss.ss_ext_sales_price) AS store_ext_sales,
        SUM(ws.ws_ext_sales_price) AS web_ext_sales,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        MIN(t_store_min.t_minute) AS min_store_minute,
        MIN(t_web_min.t_minute) AS min_web_minute,
        (
            SELECT SUM(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            JOIN web_site ws2_site ON ws2.ws_web_site_sk = ws2_site.web_site_sk
            WHERE ws2_site.web_state = s.s_state
        ) AS total_web_sales_for_state,
        CASE WHEN EXISTS (
                SELECT 1
                FROM store_sales ss2
                WHERE ss2.ss_store_sk = s.s_store_sk
                  AND ss2.ss_ext_sales_price > 5000
            ) THEN 1 ELSE 0 END AS high_store_sales_flag
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN time_dim t_store_min ON ss.ss_sold_time_sk = t_store_min.t_time_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN time_dim t_web_min ON ws.ws_sold_time_sk = t_web_min.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE t_store.t_hour BETWEEN 8 AND 22
      AND t_web.t_hour BETWEEN 8 AND 22
    GROUP BY CUBE (s.s_state, p.p_promo_name, s.s_store_sk)
),
filtered_sales AS (
    SELECT *
    FROM agg_sales
    WHERE high_store_sales_flag = 1
)
SELECT
    s_state,
    p_promo_name,
    store_id_sample,
    store_ext_sales,
    web_ext_sales,
    store_net_profit,
    store_txn_cnt,
    web_order_cnt,
    profit_status,
    min_store_minute,
    min_web_minute,
    total_web_sales_for_state,
    high_store_sales_flag,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY store_ext_sales DESC) AS sales_rank
FROM (
    SELECT * FROM filtered_sales
    UNION
    SELECT * FROM filtered_sales WHERE profit_status = 'Loss' AND store_ext_sales < 1000
) AS combined
ORDER BY store_ext_sales DESC
LIMIT 100
