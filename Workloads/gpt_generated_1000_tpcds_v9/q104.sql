WITH sales_promo_agg AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_promo_name AS promo_name,
        p.p_channel_email AS channel_email,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        CASE
            WHEN SUM(cs.cs_net_profit) > 100000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_list_price > 2000
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_channel_email
)
SELECT
    promo_sk,
    promo_name,
    total_net_profit,
    avg_discount,
    total_quantity,
    profit_category,
    CASE WHEN avg_discount > 500 THEN 'High' ELSE 'Low' END AS discount_category,
    'Email' AS channel_type
FROM sales_promo_agg
WHERE channel_email = 'Y'
UNION ALL
SELECT
    promo_sk,
    promo_name,
    total_net_profit,
    avg_discount,
    total_quantity,
    profit_category,
    CASE WHEN avg_discount > 500 THEN 'High' ELSE 'Low' END AS discount_category,
    'No Email' AS channel_type
FROM sales_promo_agg
WHERE channel_email = 'N'
ORDER BY total_net_profit DESC
LIMIT 100
