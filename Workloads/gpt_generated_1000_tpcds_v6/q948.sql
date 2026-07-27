WITH store_month AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        (
            SELECT COUNT(*)
            FROM web_sales ws
            JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
            JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
            WHERE dw.d_year = d.d_year
              AND dw.d_month_seq = d.d_month_seq
              AND regexp_like(wp.wp_url, '(?i)product')
        ) AS web_product_cnt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE s.s_city LIKE 'San%'
      AND regexp_like(s.s_store_name, '^.*Store.*$')
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        d.d_year,
        d.d_month_seq
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    sm.s_store_id,
    sm.s_store_name,
    sm.d_year,
    sm.d_month_seq,
    sm.total_sales,
    sm.total_profit,
    sm.profit_flag,
    sm.web_product_cnt,
    RANK() OVER (PARTITION BY sm.d_year ORDER BY sm.total_profit DESC) AS profit_rank_year,
    CONCAT(sm.s_city, ', ', sm.s_state) AS store_location
FROM store_month sm
WHERE EXISTS (
    SELECT 1
    FROM web_sales ws
    JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE dw.d_year = sm.d_year
      AND dw.d_month_seq = sm.d_month_seq
      AND regexp_like(wp.wp_url, '^https?://.*sale.*$')
)
ORDER BY sm.total_profit DESC
LIMIT 100
