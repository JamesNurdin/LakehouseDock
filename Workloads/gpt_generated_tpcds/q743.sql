WITH combined_fact AS (
    SELECT
        'store' AS sales_channel,
        d.d_year,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        'web' AS sales_channel,
        d.d_year,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        'catalog' AS sales_channel,
        d.d_year,
        i.i_category,
        p.p_promo_name,
        p.p_discount_active,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
),
aggregated AS (
    SELECT
        sales_channel,
        d_year,
        i_category,
        p_promo_name,
        p_discount_active,
        sum(net_profit) AS total_net_profit
    FROM combined_fact
    GROUP BY sales_channel, d_year, i_category, p_promo_name, p_discount_active
)
SELECT
    sales_channel,
    d_year,
    i_category,
    p_promo_name,
    p_discount_active,
    total_net_profit,
    row_number() OVER (PARTITION BY sales_channel ORDER BY total_net_profit DESC) AS rank_within_channel
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 20
