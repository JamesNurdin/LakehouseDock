WITH recent_dates AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    rd.d_year,
    i.i_category,
    SUM(ss.ss_net_profit) AS total_profit,
    CASE WHEN SUM(ss.ss_net_profit) > (
            SELECT AVG(ss2.ss_net_profit)
            FROM store_sales ss2
        ) THEN 'High' ELSE 'Low' END AS profit_level,
    MAX(CASE WHEN EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
        ) THEN 1 ELSE 0 END) AS has_promo
FROM store_sales ss
JOIN recent_dates rd ON ss.ss_sold_date_sk = rd.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
GROUP BY rd.d_year, i.i_category

UNION ALL

SELECT
    rd.d_year,
    i.i_category,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) > (
            SELECT AVG(ss2.ss_net_profit)
            FROM store_sales ss2
        ) THEN 'High' ELSE 'Low' END AS profit_level,
    MAX(CASE WHEN EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
        ) THEN 1 ELSE 0 END) AS has_promo
FROM catalog_sales cs
JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
GROUP BY rd.d_year, i.i_category

ORDER BY total_profit DESC
LIMIT 100
