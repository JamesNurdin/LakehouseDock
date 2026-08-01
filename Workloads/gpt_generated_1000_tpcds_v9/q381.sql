WITH
    sales_agg AS (
        SELECT
            ws.ws_item_sk AS item_sk,
            ws.ws_warehouse_sk AS warehouse_sk,
            i.i_item_id,
            i.i_product_name,
            w.w_warehouse_name,
            SUM(ws.ws_ext_sales_price) AS total_sales,
            SUM(ws.ws_net_profit) AS total_net_profit,
            COUNT(*) AS sales_count
        FROM web_sales ws
        JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td
            ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site site
            ON ws.ws_web_site_sk = site.web_site_sk
        WHERE i.i_rec_start_date <= DATE '2001-01-01'
          AND i.i_current_price > 20
          AND site.web_country = 'United States'
        GROUP BY
            ws.ws_item_sk,
            ws.ws_warehouse_sk,
            i.i_item_id,
            i.i_product_name,
            w.w_warehouse_name
    ),
    inventory_agg AS (
        SELECT
            inv.inv_item_sk AS item_sk,
            inv.inv_warehouse_sk AS warehouse_sk,
            SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
        FROM inventory inv
        GROUP BY
            inv.inv_item_sk,
            inv.inv_warehouse_sk
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_item_sk AS item_sk,
            SUM(sr.sr_return_amt) AS total_store_return_amt,
            SUM(sr.sr_net_loss) AS total_store_net_loss,
            COUNT(*) AS store_return_count
        FROM store_returns sr
        JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN time_dim td_sr
            ON sr.sr_return_time_sk = td_sr.t_time_sk
        WHERE EXISTS (
                SELECT 1
                FROM reason r
                WHERE r.r_reason_sk = sr.sr_reason_sk
                  AND r.r_reason_desc LIKE '%price%'
            )
          AND s.s_state = 'CA'
        GROUP BY sr.sr_item_sk
    ),
    web_returns_agg AS (
        SELECT
            wr.wr_item_sk AS item_sk,
            SUM(wr.wr_return_amt) AS total_web_return_amt,
            SUM(wr.wr_net_loss) AS total_web_net_loss,
            COUNT(*) AS web_return_count
        FROM web_returns wr
        JOIN web_sales ws
            ON wr.wr_order_number = ws.ws_order_number
        JOIN time_dim td_wr
            ON wr.wr_returned_time_sk = td_wr.t_time_sk
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE EXISTS (
                SELECT 1
                FROM reason r
                WHERE r.r_reason_sk = wr.wr_reason_sk
                  AND r.r_reason_desc LIKE '%wrong%'
            )
        GROUP BY wr.wr_item_sk
    )
SELECT
    s.i_item_id,
    s.i_product_name,
    s.w_warehouse_name,
    i.total_quantity_on_hand,
    s.total_sales,
    s.total_net_profit,
    COALESCE(sr.total_store_return_amt, 0) AS total_store_return_amt,
    COALESCE(sr.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
    COALESCE(wr.total_web_net_loss, 0) AS total_web_net_loss,
    (s.total_net_profit
        - COALESCE(sr.total_store_net_loss, 0)
        - COALESCE(wr.total_web_net_loss, 0)
    ) AS net_total_profit,
    RANK() OVER (
        ORDER BY (s.total_net_profit
            - COALESCE(sr.total_store_net_loss, 0)
            - COALESCE(wr.total_web_net_loss, 0)
        ) DESC
    ) AS profit_rank
FROM sales_agg s
JOIN inventory_agg i
    ON s.item_sk = i.item_sk
   AND s.warehouse_sk = i.warehouse_sk
LEFT JOIN store_returns_agg sr
    ON s.item_sk = sr.item_sk
LEFT JOIN web_returns_agg wr
    ON s.item_sk = wr.item_sk
WHERE i.total_quantity_on_hand > 50
ORDER BY net_total_profit DESC
LIMIT 100
