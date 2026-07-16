WITH agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) AS total_web_return_amount,
        COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS total_catalog_return_amount,
        (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) - COALESCE(SUM(cr.cr_return_amt_inc_tax), 0)) AS net_profit_after_returns,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
            AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN
        catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
        AND (wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000 OR wr.wr_returned_date_sk IS NULL)
        AND (cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000 OR cr.cr_returned_date_sk IS NULL)
    GROUP BY
        i.i_category,
        i.i_brand
    HAVING
        (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) - COALESCE(SUM(cr.cr_return_amt_inc_tax), 0)) > 0
)
SELECT
    a.i_category,
    a.i_brand,
    a.total_net_profit,
    a.total_web_return_amount,
    a.total_catalog_return_amount,
    a.net_profit_after_returns,
    a.distinct_orders,
    RANK() OVER (ORDER BY a.net_profit_after_returns DESC) AS profit_rank
FROM
    agg a
ORDER BY
    a.net_profit_after_returns DESC
LIMIT 50
