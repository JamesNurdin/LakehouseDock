(
    SELECT
        i.i_item_id,
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_usd,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_usd,
        COUNT(*) AS transaction_count
    FROM
        tpcds.web_sales ws
        JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
        JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.i_manufact LIKE '%callyable%'
        AND w.w_country = 'United States'
        AND ws.ws_ext_sales_price > 0
    GROUP BY
        i.i_item_id,
        w.w_warehouse_id
)
UNION ALL
(
    SELECT
        i.i_item_id,
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales_usd,
        AVG(ws.ws_ext_discount_amt) AS avg_discount_usd,
        COUNT(*) AS transaction_count
    FROM
        tpcds.web_sales ws
        JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
        JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.i_wholesale_cost > 10.00
        AND w.w_country = 'United States'
        AND ws.ws_ext_sales_price > 0
    GROUP BY
        i.i_item_id,
        w.w_warehouse_id
)
ORDER BY total_sales_usd DESC
LIMIT 100
