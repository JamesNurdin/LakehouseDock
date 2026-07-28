SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    w.w_warehouse_name,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    SUM(cr.cr_net_loss) AS total_catalog_return_loss,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss
FROM
    catalog_sales cs
    INNER JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN store_sales ss
        ON ss.ss_customer_sk = c_bill.c_customer_sk
    INNER JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN web_page wp
        ON wp.wp_customer_sk = c_bill.c_customer_sk
    INNER JOIN web_sales ws
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    w.w_warehouse_name
ORDER BY
    ib.ib_income_band_sk,
    w.w_warehouse_name
