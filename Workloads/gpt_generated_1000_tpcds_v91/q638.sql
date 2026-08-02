WITH item_promo_pages AS (
    SELECT
        i.i_item_sk,
        p.p_promo_sk,
        array_agg(DISTINCT wp.wp_url) AS page_urls
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_item_sk, p.p_promo_sk
)
SELECT
    i_cs.i_category AS category,
    i_cs.i_brand AS brand,
    p_cs.p_promo_name AS promotion_name,
    t_cs.t_hour AS sales_hour,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    COUNT(DISTINCT url.page_url) AS distinct_page_cnt,
    RANK() OVER (PARTITION BY i_cs.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank_in_category
FROM catalog_sales cs
JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN item i_promo_cs ON p_cs.p_item_sk = i_promo_cs.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i_cs.i_item_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws ON ws.ws_item_sk = i_cs.i_item_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN item i_promo_ws ON p_ws.p_item_sk = i_promo_ws.i_item_sk
LEFT JOIN item_promo_pages ipp ON ipp.i_item_sk = i_cs.i_item_sk AND ipp.p_promo_sk = p_cs.p_promo_sk
LEFT JOIN UNNEST(ipp.page_urls) AS url(page_url) ON TRUE
GROUP BY
    i_cs.i_category,
    i_cs.i_brand,
    p_cs.p_promo_name,
    t_cs.t_hour
ORDER BY total_catalog_profit DESC
LIMIT 100
