WITH store_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND p.p_purpose = 'DISCOUNT'
    GROUP BY p.p_promo_id, p.p_promo_name
),
web_agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND p.p_purpose = 'DISCOUNT'
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT
    promo_id,
    promo_name,
    SUM(total_net_paid) AS total_sales,
    COUNT(DISTINCT sales_channel) AS channels_used
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) combined
GROUP BY promo_id, promo_name
ORDER BY total_sales DESC
LIMIT 10
