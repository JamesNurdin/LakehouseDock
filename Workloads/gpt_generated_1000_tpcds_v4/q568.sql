/*
Goal: Compare total sales and refunds across catalog, web and store channels for a filtered set of items, stores and customers, while demonstrating advanced Trino features such as CTE pre‑aggregation, scalar sub‑queries, EXISTS filtering, DISTINCT counting and multi‑table joins across all 10 selected TPC‑DS tables.
*/
WITH store_sales_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        SUM(ss_quantity)               AS total_store_qty,
        SUM(ss_ext_sales_price)        AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM store_sales
    WHERE ss_quantity > 1                     -- selective filter on store sales quantity
    GROUP BY ss_item_sk, ss_store_sk
)
SELECT
    i.i_brand,
    i.i_class_id,
    s.s_state,
    cc.cc_market_manager,
    SUM(cs.cs_ext_sales_price)                         AS catalog_sales_total,
    SUM(cr.cr_refunded_cash)                           AS catalog_refunds_total,
    SUM(ws.ws_ext_sales_price)                         AS web_sales_total,
    SUM(wr.wr_refunded_cash)                           AS web_refunds_total,
    SUM(sa.total_store_sales)                          AS store_sales_total,
    COUNT(DISTINCT cs.cs_bill_customer_sk)            AS distinct_customers,
    AVG(cs.cs_ext_discount_amt)                        AS avg_catalog_discount,
    MIN(sa.total_store_qty)                            AS min_store_qty,
    MAX(sa.total_store_qty)                            AS max_store_qty,
    (
        SELECT MAX(ws3.ws_ext_sales_price)
        FROM web_sales ws3
        WHERE ws3.ws_item_sk = i.i_item_sk
    )                                                   AS max_web_sales_price
FROM catalog_sales cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN store_sales_agg sa
    ON sa.ss_item_sk = i.i_item_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE
    i.i_class_id IN (7, 8, 14)                     -- selective filter on item class
    AND i.i_container = 'Unknown'                 -- realistic literal filter
    AND s.s_state = 'CA'                          -- store location filter
    AND cc.cc_market_manager = 'John Doe'        -- call‑center manager filter
    AND cs.cs_wholesale_cost > 30.00              -- price filter on catalog sales
    AND cr.cr_refunded_cash > 100.00              -- refund amount filter
    AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_item_sk = i.i_item_sk
          AND ws2.ws_quantity > 5               -- ensure the item has a “busy” web‑sale pattern
    )
GROUP BY
    i.i_brand,
    i.i_class_id,
    s.s_state,
    cc.cc_market_manager,
    i.i_item_sk   -- needed because scalar sub‑query references i.i_item_sk
ORDER BY
    catalog_sales_total DESC
LIMIT 100
