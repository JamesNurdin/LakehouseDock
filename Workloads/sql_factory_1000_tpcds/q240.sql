WITH item_sales_stats AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_item_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
)
SELECT
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    iss.avg_sales_price,
    cr.cr_return_amount - iss.avg_sales_price AS return_vs_avg_price_diff,
    CASE
        WHEN cr.cr_return_amount > iss.avg_sales_price THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_price_category,
    iss.total_item_profit,
    iss.profit_rank
FROM catalog_returns cr
JOIN item_sales_stats iss ON cr.cr_item_sk = iss.item_sk
WHERE cr.cr_return_amount IS NOT NULL
ORDER BY cr.cr_returned_date_sk DESC
LIMIT 20
