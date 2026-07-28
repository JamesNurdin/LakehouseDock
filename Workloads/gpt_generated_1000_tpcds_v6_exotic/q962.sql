WITH promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'Other' END AS promo_channel
    FROM promotion p
    WHERE p.p_start_date_sk BETWEEN 2450900 AND 2451000
)
SELECT
    pi.p_promo_id,
    pi.promo_channel,
    'Store' AS sales_channel,
    SUM(ss.ss_net_profit) AS total_profit,
    (SELECT AVG(cs_sub.cs_net_profit) FROM catalog_sales cs_sub) AS overall_avg_profit
FROM store_sales ss
JOIN promo_info pi ON ss.ss_promo_sk = pi.p_promo_sk
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY pi.p_promo_id, pi.promo_channel
HAVING SUM(ss.ss_net_profit) > (SELECT AVG(cs_sub.cs_net_profit) FROM catalog_sales cs_sub)

UNION ALL

SELECT
    pi.p_promo_id,
    pi.promo_channel,
    'Catalog' AS sales_channel,
    SUM(cs.cs_net_profit) AS total_profit,
    (SELECT AVG(cs_sub.cs_net_profit) FROM catalog_sales cs_sub) AS overall_avg_profit
FROM catalog_sales cs
JOIN promo_info pi ON cs.cs_promo_sk = pi.p_promo_sk
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
WHERE td.t_hour BETWEEN 9 AND 17
GROUP BY pi.p_promo_id, pi.promo_channel
HAVING SUM(cs.cs_net_profit) > (SELECT AVG(cs_sub.cs_net_profit) FROM catalog_sales cs_sub)

ORDER BY total_profit DESC
