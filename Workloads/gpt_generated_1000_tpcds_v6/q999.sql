/*
Goal: Analyze the profitability of each promotion by month, combining catalog, store, and web sales together with their corresponding returns, and broken down by demographic dimensions. Only promotions that are active and generated substantial profit are shown.
*/
WITH
    -- Alias the date dimension for different roles (sold date, ship date, web page creation/access)
    d_sold AS (
        SELECT * FROM tpcds.date_dim
    ),
    d_ship AS (
        SELECT * FROM tpcds.date_dim
    ),
    d_wp_creation AS (
        SELECT * FROM tpcds.date_dim
    ),
    d_wp_access AS (
        SELECT * FROM tpcds.date_dim
    ),
    -- Alias the time dimension for different roles
    t_cs_sold AS (
        SELECT * FROM tpcds.time_dim
    ),
    t_ss_sold AS (
        SELECT * FROM tpcds.time_dim
    ),
    t_ws_sold AS (
        SELECT * FROM tpcds.time_dim
    ),
    t_sr_return AS (
        SELECT * FROM tpcds.time_dim
    )
SELECT
    p.p_promo_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number)               AS catalog_orders,
    SUM(cs.cs_net_profit)                           AS catalog_profit,
    COUNT(DISTINCT ss.ss_ticket_number)             AS store_orders,
    SUM(ss.ss_net_profit)                           AS store_profit,
    COUNT(DISTINCT ws.ws_order_number)              AS web_orders,
    SUM(ws.ws_net_profit)                           AS web_profit,
    COALESCE(SUM(sr.sr_net_loss), 0)                AS store_return_loss,
    COALESCE(SUM(wr.wr_net_loss), 0)                AS web_return_loss
FROM
    tpcds.catalog_sales cs
    JOIN d_sold               ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN d_ship               ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN t_cs_sold            ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN tpcds.customer_demographics cd_bill   ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_bill   ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.promotion p                     ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm                    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w                     ON cs.cs_warehouse_sk = w.w_warehouse_sk

    -- Store sales (inner join to share the same sold date as the catalog sales)
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
        AND ss.ss_item_sk = cs.cs_item_sk
    JOIN t_ss_sold            ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
    JOIN tpcds.customer_demographics cd_store ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN tpcds.household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
    JOIN tpcds.promotion p_ss                ON ss.ss_promo_sk = p_ss.p_promo_sk

    -- Store returns (left outer join – many sales have no returns)
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN t_sr_return    ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    LEFT JOIN tpcds.customer_demographics cd_sr_cdemo ON sr.sr_cdemo_sk = cd_sr_cdemo.cd_demo_sk
    LEFT JOIN tpcds.household_demographics hd_sr_hdemo ON sr.sr_hdemo_sk = hd_sr_hdemo.hd_demo_sk

    -- Web sales (inner join, sharing the same sold date as the catalog sales)
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_item_sk = cs.cs_item_sk
    JOIN t_ws_sold            ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN tpcds.customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
    JOIN tpcds.household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN tpcds.promotion p_ws                ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN tpcds.web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN d_wp_creation       ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN d_wp_access         ON wp.wp_access_date_sk = d_wp_access.d_date_sk

    -- Web returns (inner join – only keep rows that have a matching return)
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN tpcds.customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    JOIN tpcds.household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN tpcds.customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    JOIN tpcds.household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN tpcds.customer_demographics cd_wr_webpage  ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    p.p_discount_active = 'Y'
    AND d_sold.d_year = 2001
    AND hd_bill.hd_income_band_sk IS NOT NULL
GROUP BY
    p.p_promo_id,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING
    SUM(cs.cs_net_profit) > 10000
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    p.p_promo_id
LIMIT 100
