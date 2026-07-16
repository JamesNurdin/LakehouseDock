WITH unified_sales AS (
    SELECT cs_sold_date_sk AS sold_date_sk,
           cs_net_paid AS net_paid,
           cs_net_profit AS net_profit,
           cs_item_sk AS item_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_net_paid,
           ss_net_profit,
           ss_item_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_net_paid,
           ws_net_profit,
           ws_item_sk
    FROM web_sales
)
SELECT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    SUM(us.net_paid) AS total_net_paid,
    SUM(us.net_profit) AS total_net_profit,
    COUNT(*) AS sales_transactions
FROM unified_sales us
JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, i.i_item_id, i.i_product_name
ORDER BY total_net_profit DESC
LIMIT 100
