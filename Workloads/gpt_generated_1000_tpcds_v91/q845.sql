WITH ss_sample AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_store_sk,
        ss_promo_sk,
        ss_net_paid_inc_tax,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    p_promo_sk,
    p_promo_name,
    SUM(CASE WHEN channel = 'store' THEN net_profit ELSE 0 END) AS store_net_profit,
    SUM(CASE WHEN channel = 'catalog' THEN net_profit ELSE 0 END) AS catalog_net_profit,
    SUM(CASE WHEN channel = 'web' THEN net_profit ELSE 0 END) AS web_net_profit,
    SUM(net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(net_profit) DESC) AS promo_rank
FROM (
    SELECT
        p.p_promo_sk AS p_promo_sk,
        p.p_promo_name AS p_promo_name,
        'store' AS channel,
        ss.ss_net_profit AS net_profit,
        t.t_hour
    FROM ss_sample ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_response_target > 5
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_net_paid_inc_tax > 1000

    UNION ALL

    SELECT
        p.p_promo_sk AS p_promo_sk,
        p.p_promo_name AS p_promo_name,
        'catalog' AS channel,
        cs.cs_net_profit AS net_profit,
        t.t_hour
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_response_target > 5
      AND t.t_hour BETWEEN 9 AND 17
      AND cs.cs_net_paid_inc_tax > 1000

    UNION ALL

    SELECT
        p.p_promo_sk AS p_promo_sk,
        p.p_promo_name AS p_promo_name,
        'web' AS channel,
        ws.ws_net_profit AS net_profit,
        t.t_hour
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    WHERE p.p_discount_active = 'Y'
      AND p.p_response_target > 5
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.ws_ext_tax > 10
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_order_number = ws.ws_order_number
            AND wr.wr_returned_time_sk = t.t_time_sk
            AND wr.wr_net_loss > 0
      )
) AS combined
GROUP BY
    p_promo_sk,
    p_promo_name
ORDER BY total_net_profit DESC
LIMIT 100
