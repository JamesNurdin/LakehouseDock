WITH promo_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount_amt,
        SUM(ws.ws_ext_discount_amt) AS web_discount_amt
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_catalog = 'N'
      AND p.p_purpose = 'Unknown'
      AND cd.cd_dep_college_count >= 2
      AND ss.ss_quantity > 1
      AND ws.ws_ext_tax > 10
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT
    CASE
        WHEN (store_discount_amt + web_discount_amt) > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
    END AS discount_category,
    COUNT(*) AS promo_count,
    SUM(store_net_paid + web_net_paid) AS total_net_paid,
    AVG(store_net_profit + web_net_profit) AS avg_total_net_profit,
    SUM(store_net_profit + web_net_profit) AS sum_total_net_profit
FROM promo_agg
WHERE (store_net_paid + web_net_paid) > 5000
GROUP BY CASE
        WHEN (store_discount_amt + web_discount_amt) > 1000 THEN 'High Discount'
        ELSE 'Low Discount'
    END
HAVING SUM(store_net_profit + web_net_profit) > 2000
ORDER BY total_net_paid DESC
LIMIT 10
