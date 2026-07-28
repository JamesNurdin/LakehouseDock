WITH
    -- Store‑sales base rows filtered to a single year
    ss AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_item_sk,
            ss.ss_store_sk,
            ss.ss_hdemo_sk,
            ss.ss_addr_sk,
            ss.ss_ext_sales_price,
            ss.ss_net_profit
        FROM   store_sales ss
        JOIN   date_dim d_sale ON ss.ss_sold_date_sk = d_sale.d_date_sk
        WHERE  d_sale.d_year = 2001
    )
SELECT
    s.s_store_name,
    wsit.web_name,
    i.i_brand,
    d_sale.d_year,
    SUM(ss.ss_ext_sales_price)                         AS store_sales_total,
    SUM(ws.ws_ext_sales_price)                         AS web_sales_total,
    SUM(COALESCE(wr.wr_return_amt, 0))                 AS total_return_amount,
    SUM(ss.ss_net_profit + ws.ws_net_profit) -
    SUM(COALESCE(wr.wr_return_amt, 0))                 AS net_profit_after_returns
FROM   ss
-- Join to item (shared by store_sales, web_sales and web_returns)
JOIN   item i
       ON ss.ss_item_sk = i.i_item_sk
-- Join to store via store_sales
JOIN   store s
       ON ss.ss_store_sk = s.s_store_sk
-- Join to store’s closed‑date (date_dim reused under a different alias)
JOIN   date_dim d_store_closed
       ON s.s_closed_date_sk = d_store_closed.d_date_sk
-- Join to household demographics for the store‑sale buyer
JOIN   household_demographics hd_store
       ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
-- Join to customer address for the store‑sale buyer
JOIN   customer_address ca_store
       ON ss.ss_addr_sk = ca_store.ca_address_sk
-- Re‑use date_dim for the store‑sale date (already joined in the CTE, but needed for grouping)
JOIN   date_dim d_sale
       ON ss.ss_sold_date_sk = d_sale.d_date_sk
-- Join to web_sales via the shared item key
JOIN   web_sales ws
       ON ws.ws_item_sk = i.i_item_sk
-- Join web_sales to its sold date (different alias of date_dim)
JOIN   date_dim d_ws_sold
       ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
-- Join web_sales to its ship date (yet another date_dim alias)
JOIN   date_dim d_ws_ship
       ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
-- Join web_sales to the web page used for the visit (first alias)
JOIN   web_page wp_sales
       ON ws.ws_web_page_sk = wp_sales.wp_web_page_sk
-- Join web_sales to the web site
JOIN   web_site wsit
       ON ws.ws_web_site_sk = wsit.web_site_sk
-- Join web_site to its open date (new date_dim alias)
JOIN   date_dim d_site_open
       ON wsit.web_open_date_sk = d_site_open.d_date_sk
-- Join web_site to its close date (new date_dim alias)
JOIN   date_dim d_site_close
       ON wsit.web_close_date_sk = d_site_close.d_date_sk
-- Join web_sales to the warehouse that shipped the item
JOIN   warehouse wh
       ON ws.ws_warehouse_sk = wh.w_warehouse_sk
-- Left‑join the web_return that matches the same item and order number (rule exists)
LEFT JOIN web_returns wr
       ON wr.wr_item_sk = i.i_item_sk
      AND wr.wr_order_number = ws.ws_order_number
-- Join the reason for the return (may be NULL when no return)
LEFT JOIN reason r
       ON wr.wr_reason_sk = r.r_reason_sk
-- Join the web page that recorded the return (second alias of web_page)
LEFT JOIN web_page wp_return
       ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
-- Join date_dim for the return date (new alias)
LEFT JOIN date_dim d_return
       ON wr.wr_returned_date_sk = d_return.d_date_sk
-- Join household demographics for the refunded household (second alias)
LEFT JOIN household_demographics hd_refund
       ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
WHERE  EXISTS (
           SELECT 1
           FROM   web_returns wr_exist
           WHERE  wr_exist.wr_item_sk = ss.ss_item_sk
           AND    wr_exist.wr_return_amt > 0
       )
GROUP BY
    s.s_store_name,
    wsit.web_name,
    i.i_brand,
    d_sale.d_year
ORDER BY
    store_sales_total DESC
LIMIT 100
