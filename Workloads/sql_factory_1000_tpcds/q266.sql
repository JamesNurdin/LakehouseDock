WITH unified_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS source
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_net_profit AS net_profit,
        NULL AS call_center_sk,
        ws.ws_promo_sk AS promo_sk,
        'web' AS source
    FROM web_sales ws
),
customer_agg AS (
    SELECT
        customer_sk,
        SUM(net_profit) AS total_net_profit,
        MAX(sold_date_sk) AS latest_sold_date
    FROM unified_sales
    GROUP BY customer_sk
),
latest_detail AS (
    SELECT
        us.customer_sk,
        us.sold_date_sk,
        us.call_center_sk,
        us.promo_sk,
        us.source,
        ROW_NUMBER() OVER (PARTITION BY us.customer_sk ORDER BY us.sold_date_sk DESC) AS rn
    FROM unified_sales us
    JOIN customer_agg ca ON us.customer_sk = ca.customer_sk AND us.sold_date_sk = ca.latest_sold_date
)
SELECT
    ca.customer_sk,
    ca.total_net_profit,
    ld.sold_date_sk AS latest_purchase_date,
    ld.source AS latest_source,
    cc.cc_name AS call_center_name,
    p.p_promo_name AS promotion_name,
    CASE
        WHEN ca.total_net_profit >= 100000 THEN 'Platinum'
        WHEN ca.total_net_profit >= 50000 THEN 'Gold'
        WHEN ca.total_net_profit >= 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM customer_agg ca
LEFT JOIN latest_detail ld ON ca.customer_sk = ld.customer_sk AND ld.rn = 1
LEFT JOIN call_center cc ON ld.call_center_sk = cc.cc_call_center_sk
LEFT JOIN promotion p ON ld.promo_sk = p.p_promo_sk
ORDER BY ca.total_net_profit DESC
LIMIT 15
