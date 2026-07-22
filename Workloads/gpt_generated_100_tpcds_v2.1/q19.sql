WITH ny_sales AS (
    SELECT
        cs.cs_order_number,
        w.w_state,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE w.w_state = 'NY'
    GROUP BY cs.cs_order_number, w.w_state, i.i_category
),
ga_books_sales AS (
    SELECT
        cs.cs_order_number,
        w.w_state,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_net_profit,
        CASE WHEN SUM(cs.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE w.w_state = 'GA' AND i.i_category = 'Books'
    GROUP BY cs.cs_order_number, w.w_state, i.i_category
)
SELECT DISTINCT
    cs_order_number,
    w_state,
    i_category,
    total_net_profit,
    profit_category
FROM (
    SELECT cs_order_number, w_state, i_category, total_net_profit, profit_category
    FROM ny_sales
    UNION ALL
    SELECT cs_order_number, w_state, i_category, total_net_profit, profit_category
    FROM ga_books_sales
) combined
LIMIT 100
