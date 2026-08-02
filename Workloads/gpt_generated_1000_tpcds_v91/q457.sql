WITH base_all AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_warehouse_sk AS cs_warehouse_sk,
        cs.cs_net_profit,
        cr.cr_returned_date_sk,
        cr.cr_item_sk AS cr_item_sk,
        cr.cr_warehouse_sk AS cr_warehouse_sk,
        cr.cr_reason_sk AS cr_reason_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        r1.r_reason_desc AS cr_reason_desc,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_warehouse_sk AS ws_warehouse_sk,
        ws.ws_net_paid,
        ws.ws_order_number,
        wr.wr_returned_date_sk,
        wr.wr_item_sk AS wr_item_sk,
        wr.wr_reason_sk AS wr_reason_sk,
        wr.wr_return_amt,
        r2.r_reason_desc AS wr_reason_desc,
        ss.ss_sold_date_sk,
        ss.ss_item_sk AS ss_item_sk,
        ss.ss_net_paid,
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        w1.w_warehouse_name AS cs_warehouse_name,
        w2.w_warehouse_name AS cr_warehouse_name,
        w3.w_warehouse_name AS ws_warehouse_name,
        i_cs.i_brand,
        i_cs.i_category,
        i_cs.i_product_name,
        d1.d_date AS cs_sold_date,
        d2.d_date AS cs_ship_date,
        d3.d_date AS cr_returned_date,
        d4.d_date AS ws_sold_date,
        d5.d_date AS ws_ship_date,
        d6.d_date AS wr_returned_date,
        d7.d_date AS inv_date,
        d8.d_date AS cp_start_date,
        d9.d_date AS cp_end_date,
        d10.d_date AS ss_sold_date
    FROM catalog_page cp
    JOIN date_dim d8 ON d8.d_date_sk = cp.cp_start_date_sk
    JOIN date_dim d9 ON d9.d_date_sk = cp.cp_end_date_sk
    JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d1 ON d1.d_date_sk = cs.cs_sold_date_sk
    JOIN date_dim d2 ON d2.d_date_sk = cs.cs_ship_date_sk
    JOIN item i_cs ON i_cs.i_item_sk = cs.cs_item_sk
    JOIN warehouse w1 ON w1.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_item_sk = cs.cs_item_sk
                           AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d3 ON d3.d_date_sk = cr.cr_returned_date_sk
    JOIN item i_cr ON i_cr.i_item_sk = cr.cr_item_sk
    JOIN warehouse w2 ON w2.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN reason r1 ON r1.r_reason_sk = cr.cr_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d1.d_date_sk
                        AND ss.ss_item_sk = i_cs.i_item_sk
    JOIN item i_ss ON i_ss.i_item_sk = ss.ss_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
                       AND ws.ws_item_sk = i_cs.i_item_sk
    JOIN date_dim d4 ON d4.d_date_sk = ws.ws_sold_date_sk
    JOIN date_dim d5 ON d5.d_date_sk = ws.ws_ship_date_sk
    JOIN warehouse w3 ON w3.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN item i_ws ON i_ws.i_item_sk = ws.ws_item_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d6 ON d6.d_date_sk = wr.wr_returned_date_sk
    JOIN reason r2 ON r2.r_reason_sk = wr.wr_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
                     AND inv.inv_item_sk = i_cs.i_item_sk
                     AND inv.inv_warehouse_sk = w1.w_warehouse_sk
    JOIN date_dim d7 ON d7.d_date_sk = inv.inv_date_sk
    JOIN date_dim d10 ON d10.d_date_sk = ss.ss_sold_date_sk
),
cat_orders AS (
    SELECT DISTINCT cs_order_number AS order_number
    FROM base_all
    WHERE cs_net_profit > 0
),
web_orders AS (
    SELECT DISTINCT ws_order_number AS order_number
    FROM base_all
    WHERE ws_net_paid > 0
),
 diff_orders AS (
    SELECT order_number
    FROM cat_orders
    EXCEPT
    SELECT order_number
    FROM web_orders
),
order_agg AS (
    SELECT
        cs_order_number AS order_number,
        cp_department,
        SUM(cs_net_profit) AS total_net_profit
    FROM base_all
    GROUP BY cs_order_number, cp_department
)
SELECT
    do.order_number,
    oa.total_net_profit,
    LAG(oa.total_net_profit) OVER (PARTITION BY oa.cp_department ORDER BY do.order_number) AS prev_total_profit,
    SUM(oa.total_net_profit) OVER (PARTITION BY oa.cp_department ORDER BY do.order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_profit
FROM diff_orders do
JOIN order_agg oa ON oa.order_number = do.order_number
ORDER BY do.order_number
LIMIT 100
