WITH catalog_ret AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        td.t_hour,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_qty
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_warehouse_sk IN (7, 14, 9)
),
store_ret AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        td.t_hour,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_qty
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE sr.sr_store_sk IN (1, 2)
),
sales AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        td.t_hour,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_warehouse_sk IN (7, 14)
),
aggregated_returns AS (
    SELECT
        item_sk,
        t_hour,
        SUM(return_amount) AS total_return_amount,
        AVG(return_qty) AS avg_return_qty,
        COUNT(*) AS return_cnt
    FROM (
        SELECT * FROM catalog_ret
        UNION ALL
        SELECT * FROM store_ret
    ) r
    GROUP BY item_sk, t_hour
),
aggregated_sales AS (
    SELECT
        item_sk,
        t_hour,
        SUM(sales_amount) AS total_sales_amount,
        SUM(net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM sales
    GROUP BY item_sk, t_hour
)
SELECT
    i.i_category,
    COALESCE(ar.t_hour, asl.t_hour) AS hour_of_day,
    COALESCE(ar.total_return_amount, 0) AS total_return_amount,
    COALESCE(ar.avg_return_qty, 0) AS avg_return_quantity,
    COALESCE(asl.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(asl.total_net_profit, 0) AS total_net_profit,
    (COALESCE(asl.total_net_profit, 0) - COALESCE(ar.total_return_amount, 0)) AS net_contribution,
    RANK() OVER (PARTITION BY i.i_category ORDER BY (COALESCE(asl.total_net_profit, 0) - COALESCE(ar.total_return_amount, 0)) DESC) AS net_contribution_rank
FROM aggregated_returns ar
FULL OUTER JOIN aggregated_sales asl
    ON ar.item_sk = asl.item_sk AND ar.t_hour = asl.t_hour
JOIN item i
    ON i.i_item_sk = COALESCE(ar.item_sk, asl.item_sk)
WHERE i.i_category IN ('Electronics', 'Books', 'Clothing')
  AND COALESCE(ar.t_hour, asl.t_hour) BETWEEN 8 AND 20
  AND COALESCE(asl.total_sales_amount, 0) > 1000
ORDER BY i.i_category, hour_of_day
