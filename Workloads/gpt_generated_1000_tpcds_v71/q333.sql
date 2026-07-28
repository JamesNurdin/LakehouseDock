WITH
    store_ret AS (
        SELECT
            sr.sr_ticket_number,
            SUM(sr.sr_return_amt)      AS store_return_total,
            SUM(sr.sr_net_loss)        AS store_net_loss
        FROM store_returns sr
        GROUP BY sr.sr_ticket_number
    ),
    web_ret AS (
        SELECT
            wr.wr_order_number,
            SUM(wr.wr_return_amt)      AS web_return_total,
            SUM(wr.wr_net_loss)        AS web_net_loss
        FROM web_returns wr
        GROUP BY wr.wr_order_number
    )
SELECT
    d_sold.d_year                                 AS sale_year,
    ws_site.web_name                              AS website,
    cc.cc_state                                   AS call_center_state,
    SUM(ws.ws_net_profit)                         AS total_net_profit,
    SUM(COALESCE(sr_agg.store_return_total, 0))   AS total_store_return_amount,
    SUM(COALESCE(wr_agg.web_return_total, 0))    AS total_web_return_amount,
    CASE
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'Low'
    END                                           AS profit_category,
    COUNT(DISTINCT w.w_warehouse_name)            AS distinct_warehouses,
    COUNT(DISTINCT cp.cp_catalog_page_id)         AS distinct_catalog_pages
FROM web_sales ws
    /* sold date */
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    /* shipped date */
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    /* sold time */
    JOIN time_dim t_sold ON ws.ws_sold_time_sk = t_sold.t_time_sk
    /* warehouse */
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    /* web site */
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    /* call center (using closed date as example) */
    JOIN call_center cc ON cc.cc_closed_date_sk = d_sold.d_date_sk
    /* catalog page (using end date) */
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_sold.d_date_sk
    /* billing customer demographics */
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    /* shipping customer demographics (second alias) */
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    /* aggregated store returns */
    LEFT JOIN store_ret sr_agg ON sr_agg.sr_ticket_number = ws.ws_order_number
    /* aggregated web returns */
    LEFT JOIN web_ret wr_agg ON wr_agg.wr_order_number = ws.ws_order_number
WHERE t_sold.t_shift = 'first'
GROUP BY
    d_sold.d_year,
    ws_site.web_name,
    cc.cc_state
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
