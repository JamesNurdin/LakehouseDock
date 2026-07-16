WITH catalog AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_item_sk AS item_sk,
           cs_net_profit AS net_profit
    FROM catalog_sales
), store AS (
    SELECT ss_sold_date_sk AS sold_date_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit
    FROM store_sales
), web AS (
    SELECT ws_sold_date_sk AS sold_date_sk,
           ws_item_sk AS item_sk,
           ws_net_profit AS net_profit
    FROM web_sales
), combined AS (
    SELECT sold_date_sk, item_sk, net_profit FROM catalog
    UNION ALL
    SELECT sold_date_sk, item_sk, net_profit FROM store
    UNION ALL
    SELECT sold_date_sk, item_sk, net_profit FROM web
)
SELECT
    d.d_year,
    i.i_category,
    SUM(c.net_profit) AS total_net_profit,
    COUNT(*) AS transaction_count,
    AVG(c.net_profit) AS avg_profit_per_transaction,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(c.net_profit) DESC) AS category_rank
FROM combined c
JOIN date_dim d ON c.sold_date_sk = d.d_date_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, i.i_category
ORDER BY d.d_year, total_net_profit DESC
LIMIT 20
