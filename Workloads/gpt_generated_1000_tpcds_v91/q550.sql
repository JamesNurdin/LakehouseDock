/*
  Goal: Analyze sales and returns across all channels by joining all TPC‑DS tables, applying detailed filters, comparing quantities to a scalar subquery, aggregating metrics with a CUBE grouping, and returning the top 100 aggregated rows.
*/
WITH base1 AS (
    SELECT
        cc.cc_name                     AS call_center_name,
        i.i_category                   AS item_category,
        wp.wp_type                     AS page_type,
        w.w_state                      AS warehouse_state,
        r.r_reason_desc                AS reason_desc,
        cs.cs_quantity                 AS cs_qty,
        cs.cs_net_paid                 AS cs_net_paid,
        cs.cs_net_profit               AS cs_net_profit,
        ss.ss_quantity                 AS ss_qty,
        ss.ss_net_paid                 AS ss_net_paid,
        ss.ss_net_profit               AS ss_net_profit,
        ws.ws_quantity                 AS ws_qty,
        ws.ws_net_paid                 AS ws_net_paid,
        ws.ws_net_profit               AS ws_net_profit,
        wr.wr_return_quantity          AS wr_qty,
        wr.wr_return_amt               AS wr_return_amt,
        wr.wr_net_loss                 AS wr_net_loss
    FROM catalog_sales cs
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w             ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i                  ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer_demographics cd1 ON cs.cs_bill_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON cs.cs_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN store_sales ss          ON ss.ss_item_sk   = i.i_item_sk
                                 AND ss.ss_cdemo_sk = cd1.cd_demo_sk
                                 AND ss.ss_hdemo_sk = hd1.hd_demo_sk
    JOIN web_sales ws            ON ws.ws_item_sk   = i.i_item_sk
                                 AND ws.ws_bill_cdemo_sk = cd1.cd_demo_sk
                                 AND ws.ws_bill_hdemo_sk = hd1.hd_demo_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r                ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state               = 'CA'
      AND w.w_city                 = 'Dallas'
      AND i.i_brand                = 'Brand#15'
      AND wp.wp_image_count        > 3
      AND r.r_reason_desc          = 'Defective product'
),
base2 AS (
    SELECT
        cc.cc_name                     AS call_center_name,
        i.i_category                   AS item_category,
        wp.wp_type                     AS page_type,
        w.w_state                      AS warehouse_state,
        r.r_reason_desc                AS reason_desc,
        cs.cs_quantity                 AS cs_qty,
        cs.cs_net_paid                 AS cs_net_paid,
        cs.cs_net_profit               AS cs_net_profit,
        ss.ss_quantity                 AS ss_qty,
        ss.ss_net_paid                 AS ss_net_paid,
        ss.ss_net_profit               AS ss_net_profit,
        ws.ws_quantity                 AS ws_qty,
        ws.ws_net_paid                 AS ws_net_paid,
        ws.ws_net_profit               AS ws_net_profit,
        wr.wr_return_quantity          AS wr_qty,
        wr.wr_return_amt               AS wr_return_amt,
        wr.wr_net_loss                 AS wr_net_loss
    FROM catalog_sales cs
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w             ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN item i                  ON cs.cs_item_sk        = i.i_item_sk
    JOIN customer_demographics cd2 ON cs.cs_ship_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON cs.cs_ship_hdemo_sk = hd2.hd_demo_sk
    JOIN store_sales ss          ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp             ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr          ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r                ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cc.cc_company                = 1
      AND w.w_gmt_offset               = -5.00
      AND i.i_rec_end_date             < DATE '2002-01-01'
      AND wp.wp_rec_start_date         >= DATE '2000-01-01'
      AND r.r_reason_desc              = 'Late delivery'
)
SELECT
    call_center_name,
    item_category,
    page_type,
    warehouse_state,
    reason_desc,
    COUNT(*)                         AS transaction_count,
    SUM(cs_qty)                      AS total_catalog_qty,
    SUM(ss_qty)                      AS total_store_qty,
    SUM(ws_qty)                      AS total_web_qty,
    SUM(wr_qty)                      AS total_return_qty,
    SUM(cs_net_paid)                 AS total_catalog_sales,
    SUM(ss_net_paid)                 AS total_store_sales,
    SUM(ws_net_paid)                 AS total_web_sales,
    SUM(wr_return_amt)               AS total_return_amount,
    SUM(cs_net_profit)               AS total_catalog_profit,
    SUM(ss_net_profit)               AS total_store_profit,
    SUM(ws_net_profit)               AS total_web_profit,
    SUM(wr_net_loss)                 AS total_return_loss,
    AVG(cs_net_paid)                 AS avg_catalog_sale,
    MIN(cs_net_paid)                 AS min_catalog_sale,
    MAX(cs_net_paid)                 AS max_catalog_sale
FROM (
    SELECT * FROM base1
    UNION
    SELECT * FROM base2
) u
WHERE cs_qty > (
    SELECT MAX(cs_quantity)
    FROM catalog_sales
    WHERE cs_sold_date_sk = 2451110
)
GROUP BY CUBE (
    call_center_name,
    item_category,
    page_type,
    warehouse_state,
    reason_desc
)
ORDER BY transaction_count DESC
LIMIT 100
