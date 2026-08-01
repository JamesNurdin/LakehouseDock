WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        -- count distinct web pages visited for this promotion via a lateral subquery
        page_stats.distinct_page_cnt
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(DISTINCT wp.wp_web_page_id) AS distinct_page_cnt
        FROM web_page wp
        WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
    ) AS page_stats
    WHERE p.p_discount_active = 'Y'
      AND p.p_channel_tv = 'Y'
      AND p.p_start_date_sk BETWEEN 2450192 AND 2450675
      AND ss.ss_ext_list_price > 1000
      AND ws.ws_ext_wholesale_cost < 2000
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_promo_sk = p.p_promo_sk
            AND ws2.ws_net_paid > 500
      )
    GROUP BY p.p_promo_id, p.p_promo_name, page_stats.distinct_page_cnt
),
promo_summary AS (
    SELECT
        pa.p_promo_id AS promo_id,
        pa.p_promo_name AS promo_name,
        (pa.store_net_profit + pa.web_net_profit) AS total_net_profit,
        pa.distinct_page_cnt
    FROM promo_agg pa
    WHERE (pa.store_net_profit + pa.web_net_profit) > 5000
)
SELECT DISTINCT
    promo_id,
    promo_name,
    total_net_profit,
    distinct_page_cnt
FROM promo_summary
GROUP BY promo_id, promo_name, total_net_profit, distinct_page_cnt
HAVING distinct_page_cnt >= 3
ORDER BY total_net_profit DESC
LIMIT 100
