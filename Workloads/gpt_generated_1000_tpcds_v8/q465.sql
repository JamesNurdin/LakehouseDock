WITH
    sampled_web AS (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (5)   -- sample ~5% of rows
    ),
    sales_without_returns AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    item_union AS (
        SELECT cs_item_sk AS item_sk FROM catalog_sales
        UNION
        SELECT ws_item_sk FROM sampled_web
    ),
    joined_data AS (
        SELECT
            cr.cr_item_sk,
            cs.cs_item_sk,
            ws.ws_item_sk,
            cr.cr_return_amount,
            cr.cr_store_credit,
            cr.cr_fee,
            cs.cs_net_profit,
            ws.ws_net_profit,
            sr.sr_net_loss,
            sr.sr_fee,
            COALESCE(td_cr.t_hour, td_cs.t_hour) AS t_hour,
            cs.cs_order_number
        FROM catalog_returns cr
        FULL OUTER JOIN catalog_sales cs
            ON cr.cr_item_sk = cs.cs_item_sk
           AND cr.cr_order_number = cs.cs_order_number
        LEFT JOIN time_dim td_cr
            ON cr.cr_returned_time_sk = td_cr.t_time_sk
        LEFT JOIN time_dim td_cs
            ON cs.cs_sold_time_sk = td_cs.t_time_sk
        LEFT JOIN store_returns sr
            ON sr.sr_return_time_sk = td_cr.t_time_sk
        LEFT JOIN sampled_web ws
            ON ws.ws_sold_time_sk = td_cr.t_time_sk
        WHERE
            (cr.cr_return_amount > 20 OR cr.cr_return_amount IS NULL)
            AND (cs.cs_net_profit > 0 OR cs.cs_net_profit IS NULL)
            AND (sr.sr_fee BETWEEN 10 AND 100 OR sr.sr_fee IS NULL)
            AND (ws.ws_quantity > 1 OR ws.ws_quantity IS NULL)
            AND COALESCE(td_cr.t_hour, td_cs.t_hour) BETWEEN 8 AND 12
            AND (cr.cr_store_credit = 0 OR cr.cr_store_credit IS NULL)
            AND EXISTS (
                SELECT 1 FROM sales_without_returns swr
                WHERE swr.cs_order_number = cs.cs_order_number
            )
    ),
    agg1 AS (
        SELECT
            cr_item_sk,
            t_hour,
            SUM(cr_return_amount) AS sum_return_amount,
            SUM(cs_net_profit) AS sum_sales_profit,
            SUM(sr_net_loss) AS sum_store_loss
        FROM joined_data
        GROUP BY GROUPING SETS (
            (cr_item_sk, t_hour),
            (cr_item_sk),
            (t_hour),
            ()
        )
    ),
    final AS (
        SELECT
            cr_item_sk,
            t_hour,
            sum_return_amount,
            sum_sales_profit,
            sum_store_loss
        FROM agg1
        WHERE sum_return_amount > 100
           OR sum_sales_profit > 500
    )
SELECT DISTINCT
    cr_item_sk,
    t_hour,
    sum_return_amount,
    sum_sales_profit,
    sum_store_loss
FROM final
ORDER BY t_hour, sum_return_amount DESC
LIMIT 100
