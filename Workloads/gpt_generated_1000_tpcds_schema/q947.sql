WITH union_data AS (
    -- First branch: full outer join between item and web_sales with string filters and a scalar subquery in the WHERE clause
    SELECT
        COALESCE(i.i_item_sk, ws.ws_item_sk) AS i_item_sk,
        COALESCE(i.i_product_name, '')        AS product_name,
        ws.ws_order_number                     AS order_number,
        ws.ws_ext_sales_price                  AS metric_value,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM item i
    FULL OUTER JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    WHERE regexp_like(i.i_product_name, '[0-9]{3}')               -- product name contains three digits
      AND i.i_category LIKE '%stable%'                             -- category contains the word "stable"
      AND ws.ws_order_number IN (
            SELECT wr.wr_order_number
            FROM web_returns wr
            WHERE wr.wr_return_amt > 100
        )

    UNION

    -- Second branch: inner join between item and web_returns with different string logic and an EXISTS subquery
    SELECT
        i.i_item_sk                     AS i_item_sk,
        i.i_product_name                AS product_name,
        wr.wr_order_number              AS order_number,
        wr.wr_return_amt                AS metric_value,
        CASE WHEN wr.wr_return_amt > 0 THEN 'Return' ELSE 'NoReturn' END AS profit_flag
    FROM item i
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    WHERE i.i_formulation LIKE '%sky%'
      AND EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = i.i_item_sk
              AND ws2.ws_ext_sales_price > 1000
        )
)
SELECT
    COUNT(DISTINCT i_item_sk)                                 AS distinct_item_count,
    SUM(DISTINCT metric_value)                                AS distinct_metric_sum,
    COUNT(DISTINCT CASE WHEN profit_flag = 'Profit' THEN i_item_sk END) AS profit_item_count
FROM union_data
LIMIT 100
