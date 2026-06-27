WITH store_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id, d.d_year
),
web_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        'web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id, d.d_year
),
catalog_sales_agg AS (
    SELECT
        p.p_promo_id,
        d.d_year,
        'catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id, d.d_year
)
SELECT
    p_promo_id,
    d_year,
    channel,
    total_net_profit,
    total_quantity,
    distinct_customers
FROM (
    SELECT p_promo_id, d_year, channel, total_net_profit, total_quantity, distinct_customers FROM store_sales_agg
    UNION ALL
    SELECT p_promo_id, d_year, channel, total_net_profit, total_quantity, distinct_customers FROM web_sales_agg
    UNION ALL
    SELECT p_promo_id, d_year, channel, total_net_profit, total_quantity, distinct_customers FROM catalog_sales_agg
) AS all_sales
WHERE total_net_profit > 0
ORDER BY d_year DESC, total_net_profit DESC
LIMIT 100
