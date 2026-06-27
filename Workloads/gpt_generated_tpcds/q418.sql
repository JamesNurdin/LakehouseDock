WITH store_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
web_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_date >= DATE '2000-01-01' AND d.d_date < DATE '2001-01-01'
),
all_sales AS (
    SELECT d_year, i_category, net_profit FROM store_sales_agg
    UNION ALL
    SELECT d_year, i_category, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT d_year, i_category, net_profit FROM web_sales_agg
)
SELECT
    d_year,
    i_category,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM all_sales
GROUP BY d_year, i_category
ORDER BY total_net_profit DESC
LIMIT 20
