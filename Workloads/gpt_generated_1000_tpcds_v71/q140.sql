WITH combined AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        (
            SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)
            - SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss)
        ) AS total_profit
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                             AND sr.sr_item_sk = ss.ss_item_sk
                             AND sr.sr_store_sk = s.s_store_sk
                             AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                               AND cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                         AND ws.ws_item_sk = i.i_item_sk
                         AND ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                           AND wr.wr_item_sk = i.i_item_sk
                           AND wr.wr_order_number = ws.ws_order_number
        JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
                         AND inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND i.i_brand = 'brandbrand #4'
        AND w.w_state = 'CA'
        AND cc.cc_class = 'A'
        AND cp.cp_type = 'PROMO'
        AND ws.ws_net_profit > 0
    GROUP BY
        d.d_year,
        s.s_store_id,
        s.s_store_name
)
SELECT
    d_year,
    s_store_id,
    s_store_name,
    total_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank,
    store_sales_profit,
    web_sales_profit,
    catalog_returns_loss,
    store_returns_loss,
    web_returns_loss
FROM combined
ORDER BY d_year, profit_rank
LIMIT 100
