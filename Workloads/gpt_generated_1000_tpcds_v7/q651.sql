/*
Goal: Identify the most profitable web pages for a specific warehouse county, showing sales performance per item and ranking pages by total sales within each county. The query joins all five TPC‑DS tables, applies several realistic filters, uses a correlated scalar subquery, and ranks the results with window functions.
*/
WITH sales_agg AS (
    SELECT
        ws.ws_web_page_sk,
        wp.wp_url,
        w.w_county,
        i.i_item_id,
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price)      AS total_sales,
        SUM(ws.ws_net_profit)           AS total_profit,
        COUNT(*)                        AS order_cnt,
        AVG(ws.ws_sales_price)          AS avg_sales_price,
        (
            SELECT AVG(ws2.ws_sales_price)
            FROM   web_sales ws2
            WHERE  ws2.ws_item_sk = ws.ws_item_sk
        )                               AS item_avg_price
    FROM   web_sales   ws
    JOIN   item        i  ON ws.ws_item_sk    = i.i_item_sk
    JOIN   customer    c  ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN   warehouse   w  ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN   web_page    wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE  ws.ws_sold_date_sk BETWEEN 2449000 AND 2452000          -- recent sales window
      AND  i.i_current_price    > 50                               -- mid‑range priced items
      AND  w.w_county           = 'Mobile County'                -- focus county
      AND  wp.wp_char_count    > 2000                           -- richer page content
    GROUP BY
        ws.ws_web_page_sk,
        wp.wp_url,
        w.w_county,
        i.i_item_id,
        ws.ws_item_sk
)
SELECT
    wp_url,
    w_county,
    total_sales,
    total_profit,
    order_cnt,
    avg_sales_price,
    item_avg_price,
    RANK()       OVER (PARTITION BY w_county ORDER BY total_sales DESC)        AS sales_rank_by_county,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC)                           AS overall_profit_rank
FROM   sales_agg
WHERE  total_sales > 10000                         -- keep only high‑volume pages
ORDER BY sales_rank_by_county, wp_url
LIMIT  100
