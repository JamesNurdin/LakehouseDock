WITH aggregated AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(f.net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        AVG(f.net_profit) AS avg_profit
    FROM (
        SELECT ss.ss_sold_date_sk AS date_sk,
               ss.ss_item_sk AS item_sk,
               ss.ss_net_profit AS net_profit
        FROM store_sales ss
        UNION ALL
        SELECT cs.cs_sold_date_sk AS date_sk,
               cs.cs_item_sk AS item_sk,
               cs.cs_net_profit AS net_profit
        FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_sold_date_sk AS date_sk,
               ws.ws_item_sk AS item_sk,
               ws.ws_net_profit AS net_profit
        FROM web_sales ws
    ) f
    JOIN date_dim d ON f.date_sk = d.d_date_sk
    JOIN item i ON f.item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY d.d_year, i.i_category
    HAVING SUM(f.net_profit) > 0
)
SELECT *
FROM (
    SELECT
        d_year,
        i_category,
        total_profit,
        txn_count,
        avg_profit,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rank_in_year
    FROM aggregated
) t
WHERE rank_in_year <= 10
ORDER BY d_year, rank_in_year
