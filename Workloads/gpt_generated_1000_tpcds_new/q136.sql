WITH ss_join AS (
    SELECT
        s.s_store_name,
        d1.d_year,
        p.p_promo_name,
        ss.ss_ext_sales_price AS store_ext_sales,
        ss.ss_quantity,
        ss.ss_ticket_number,
        ws.ws_ext_sales_price AS web_ext_sales,
        ws.ws_net_profit,
        p.p_discount_active,
        wp.wp_link_count
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d1.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND s.s_state = 'CA'
      AND p.p_channel_demo = 'N'
      AND p.p_discount_active = 'N'
      AND wp.wp_link_count > 15
      AND ss.ss_quantity > 2
      AND ws.ws_net_profit > 0
),
ss_join_2 AS (
    SELECT
        s.s_store_name,
        d2.d_year,
        p2.p_promo_name,
        ss2.ss_ext_sales_price AS store_ext_sales,
        ss2.ss_quantity,
        ss2.ss_ticket_number,
        ws2.ws_ext_sales_price AS web_ext_sales,
        ws2.ws_net_profit,
        p2.p_discount_active,
        wp2.wp_link_count
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ss2.ss_sold_time_sk = t2.t_time_sk
    JOIN store s ON ss2.ss_store_sk = s.s_store_sk
    JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
    JOIN web_sales ws2 ON ws2.ws_sold_date_sk = d2.d_date_sk
    JOIN web_page wp2 ON ws2.ws_web_page_sk = wp2.wp_web_page_sk
    WHERE d2.d_year = 2002
      AND t2.t_hour BETWEEN 10 AND 18
      AND s.s_state = 'NY'
      AND p2.p_channel_demo = 'N'
      AND p2.p_discount_active = 'N'
      AND wp2.wp_link_count > 12
      AND ss2.ss_quantity > 1
      AND ws2.ws_net_profit > 5
)
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    SUM(store_ext_sales) AS total_store_sales,
    SUM(web_ext_sales) AS total_web_sales,
    COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
    AVG(ws_net_profit) AS avg_web_profit,
    CASE WHEN p_discount_active = 'Y' THEN SUM(web_ext_sales) ELSE 0 END AS promo_web_sales
FROM ss_join
GROUP BY s_store_name, d_year, p_promo_name, p_discount_active
UNION DISTINCT
SELECT
    s_store_name,
    d_year,
    p_promo_name,
    SUM(store_ext_sales) AS total_store_sales,
    SUM(web_ext_sales) AS total_web_sales,
    COUNT(DISTINCT ss_ticket_number) AS store_txn_cnt,
    AVG(ws_net_profit) AS avg_web_profit,
    CASE WHEN p_discount_active = 'Y' THEN SUM(web_ext_sales) ELSE 0 END AS promo_web_sales
FROM ss_join_2
GROUP BY s_store_name, d_year, p_promo_name, p_discount_active
ORDER BY total_store_sales DESC
LIMIT 100
