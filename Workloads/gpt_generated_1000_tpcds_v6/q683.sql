WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk                         AS web_site_sk,
        ws.ws_sold_date_sk                        AS sold_date_sk,
        td.t_hour                                 AS hour_of_day,
        SUM(ws.ws_net_profit)                     AS total_profit,
        SUM(ws.ws_quantity)                       AS total_quantity,
        AVG(ws.ws_sales_price)                    AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    INNER JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN tpcds.time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    INNER JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    INNER JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = ws.ws_item_sk
       AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    WHERE i.i_class_id IN (1, 3, 5)
      AND wsit.web_mkt_id = 2
      AND td.t_hour BETWEEN 8 AND 18
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p2
          WHERE p2.p_item_sk = i.i_item_sk
            AND p2.p_discount_active = 'Y'
      )
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, td.t_hour
)
SELECT
    wsit.web_name                         AS web_site_name,
    AVG(s.total_profit)                   AS avg_daily_profit,
    SUM(s.total_quantity)                 AS total_units_sold
FROM sales_agg s
INNER JOIN tpcds.web_site wsit
    ON s.web_site_sk = wsit.web_site_sk
GROUP BY wsit.web_name
HAVING AVG(s.total_profit) > 10000
ORDER BY avg_daily_profit DESC
LIMIT 10
