WITH
    sampled_inventory AS (
        SELECT *
        FROM inventory TABLESAMPLE BERNOULLI (10)
    ),
    store_agg AS (
        SELECT
            d_sold.d_year AS year,
            i.i_category AS category,
            s.s_state AS region,
            'Store' AS channel,
            SUM(ss.ss_net_profit) AS net_profit,
            COUNT(DISTINCT ss.ss_ticket_number) AS orders,
            SUM(COALESCE(sr.sr_net_loss, 0)) AS returns_loss
        FROM store_sales ss
        INNER JOIN date_dim d_sold
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
        INNER JOIN time_dim t_sold
            ON ss.ss_sold_time_sk = t_sold.t_time_sk
        INNER JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        INNER JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        INNER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN date_dim d_return_sr
            ON sr.sr_returned_date_sk = d_return_sr.d_date_sk
        LEFT JOIN time_dim t_return_sr
            ON sr.sr_return_time_sk = t_return_sr.t_time_sk
        LEFT JOIN date_dim d_store_closed
            ON s.s_closed_date_sk = d_store_closed.d_date_sk
        INNER JOIN sampled_inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d_sold.d_date_sk
        INNER JOIN warehouse wh
            ON inv.inv_warehouse_sk = wh.w_warehouse_sk
        WHERE inv.inv_quantity_on_hand > 0
          AND d_sold.d_year = 2002
          AND EXISTS (
                SELECT 1
                FROM web_page wp_chk
                WHERE wp_chk.wp_customer_sk = c.c_customer_sk
                  AND wp_chk.wp_type = 'Home'
          )
        GROUP BY ROLLUP (d_sold.d_year, i.i_category, s.s_state)
        HAVING SUM(ss.ss_net_profit) > 500
    ),
    web_agg AS (
        SELECT
            d_sold.d_year AS year,
            i.i_category AS category,
            we.web_state AS region,
            'Web' AS channel,
            SUM(ws.ws_net_profit) AS net_profit,
            COUNT(DISTINCT ws.ws_order_number) AS orders,
            SUM(COALESCE(wr.wr_net_loss, 0)) AS returns_loss
        FROM web_sales ws
        INNER JOIN date_dim d_sold
            ON ws.ws_sold_date_sk = d_sold.d_date_sk
        INNER JOIN date_dim d_ship
            ON ws.ws_ship_date_sk = d_ship.d_date_sk
        INNER JOIN time_dim t_sold
            ON ws.ws_sold_time_sk = t_sold.t_time_sk
        INNER JOIN item i
            ON ws.ws_item_sk = i.i_item_sk
        INNER JOIN warehouse wh
            ON ws.ws_warehouse_sk = wh.w_warehouse_sk
        INNER JOIN ship_mode sm
            ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN web_site we
            ON ws.ws_web_site_sk = we.web_site_sk
        INNER JOIN web_page wp
            ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN customer c_bill
            ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        INNER JOIN customer_demographics cd_bill
            ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        INNER JOIN customer_address ca_bill
            ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        INNER JOIN customer c_ship
            ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
        INNER JOIN customer_demographics cd_ship
            ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        INNER JOIN customer_address ca_ship
            ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        LEFT JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN date_dim d_return
            ON wr.wr_returned_date_sk = d_return.d_date_sk
        LEFT JOIN web_page wp_ret
            ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
        WHERE d_sold.d_year = 2002
        GROUP BY ROLLUP (d_sold.d_year, i.i_category, we.web_state)
        HAVING SUM(ws.ws_net_profit) > 1000
    )
SELECT
    channel,
    year,
    category,
    region,
    SUM(net_profit) AS net_profit,
    SUM(orders) AS orders,
    SUM(returns_loss) AS returns_loss
FROM (
    SELECT channel, year, category, region, net_profit, orders, returns_loss
    FROM store_agg
    UNION ALL
    SELECT channel, year, category, region, net_profit, orders, returns_loss
    FROM web_agg
) combined
GROUP BY ROLLUP (channel, year, category, region)
HAVING SUM(net_profit) > 2000
ORDER BY channel, year, category, region
