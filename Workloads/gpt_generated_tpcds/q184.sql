WITH store_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        p.p_promo_name AS promo_name,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND p.p_discount_active = 'Y'
),
catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        p.p_promo_name AS promo_name,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND p.p_discount_active = 'Y'
),
web_sales_agg AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        p.p_promo_name AS promo_name,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_date BETWEEN DATE '2000-01-01' AND DATE '2002-12-31'
      AND p.p_discount_active = 'Y'
)
SELECT
    year,
    month,
    promo_name,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count
FROM (
    SELECT year, month, promo_name, net_profit FROM store_sales_agg
    UNION ALL
    SELECT year, month, promo_name, net_profit FROM catalog_sales_agg
    UNION ALL
    SELECT year, month, promo_name, net_profit FROM web_sales_agg
) AS combined_sales
GROUP BY year, month, promo_name
ORDER BY year, month, total_net_profit DESC
