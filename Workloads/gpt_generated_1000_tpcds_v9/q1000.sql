WITH joined AS (
    SELECT
        d_ws_sold.d_date AS sell_date,
        sm_ws.sm_code AS ship_mode,
        cd_bill.cd_credit_rating AS credit_rating,
        ws.ws_net_profit AS net_profit,
        cr.cr_return_amount AS catalog_return_amount,
        sr.sr_return_amt AS store_return_amount,
        wr.wr_return_amt AS web_return_amount,
        c_bill.c_customer_sk AS bill_customer_sk,
        ib_bill.ib_lower_bound AS income_lower,
        ib_bill.ib_upper_bound AS income_upper
    FROM web_sales ws
    /* web_sales dimension joins */
    INNER JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    LEFT JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    INNER JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    INNER JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    INNER JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    INNER JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    INNER JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    INNER JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    INNER JOIN customer_demographics cd_ship
        ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    INNER JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    /* join income_band for a household demographic */
    INNER JOIN income_band ib_bill
        ON hd_bill.hd_income_band_sk = ib_bill.ib_income_band_sk
    /* web_returns – joins through order number and its own dimensions */
    INNER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    INNER JOIN date_dim d_wr_returned
        ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
    INNER JOIN time_dim t_wr_returned
        ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
    INNER JOIN customer c_wr_refund
        ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    INNER JOIN customer c_wr_returning
        ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    INNER JOIN customer_demographics cd_wr_refund
        ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    INNER JOIN customer_demographics cd_wr_returning
        ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    INNER JOIN household_demographics hd_wr_refund
        ON wr.wr_refunded_hdemo_sk = hd_wr_refund.hd_demo_sk
    INNER JOIN household_demographics hd_wr_returning
        ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    INNER JOIN customer_address ca_wr_refund
        ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    INNER JOIN customer_address ca_wr_returning
        ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    /* store_returns – linked via the bill‑customer dimension and its own date/time */
    INNER JOIN store_returns sr
        ON sr.sr_customer_sk = c_bill.c_customer_sk
    INNER JOIN date_dim d_sr_returned
        ON sr.sr_returned_date_sk = d_sr_returned.d_date_sk
    INNER JOIN time_dim t_sr_returned
        ON sr.sr_return_time_sk = t_sr_returned.t_time_sk
    INNER JOIN customer_demographics cd_sr_cdemo
        ON sr.sr_cdemo_sk = cd_sr_cdemo.cd_demo_sk
    INNER JOIN household_demographics hd_sr_hdemo
        ON sr.sr_hdemo_sk = hd_sr_hdemo.hd_demo_sk
    INNER JOIN customer_address ca_sr_addr
        ON sr.sr_addr_sk = ca_sr_addr.ca_address_sk
    /* catalog_returns – attached through the same date/time keys as web_sales (valid join rule) */
    INNER JOIN date_dim d_cr_returned
        ON ws.ws_sold_date_sk = d_cr_returned.d_date_sk
    INNER JOIN time_dim t_cr_returned
        ON ws.ws_sold_time_sk = t_cr_returned.t_time_sk
    INNER JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
        AND cr.cr_returned_time_sk = t_cr_returned.t_time_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    INNER JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    INNER JOIN customer c_cr_refunded
        ON cr.cr_refunded_customer_sk = c_cr_refunded.c_customer_sk
    INNER JOIN customer c_cr_returning
        ON cr.cr_returning_customer_sk = c_cr_returning.c_customer_sk
    INNER JOIN customer_demographics cd_cr_refunded
        ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    INNER JOIN customer_demographics cd_cr_returning
        ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    INNER JOIN household_demographics hd_cr_refunded
        ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
    INNER JOIN household_demographics hd_cr_returning
        ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
    INNER JOIN customer_address ca_cr_refunded
        ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
    INNER JOIN customer_address ca_cr_returning
        ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk
    /* restrict to a single calendar year */
    WHERE d_ws_sold.d_date >= DATE '2001-01-01'
      AND d_ws_sold.d_date < DATE '2002-01-01'
),
aggregated AS (
    SELECT
        sell_date,
        ship_mode,
        credit_rating,
        SUM(net_profit) AS total_net_profit,
        SUM(catalog_return_amount) AS total_catalog_return_amount,
        SUM(store_return_amount) AS total_store_return_amount,
        SUM(web_return_amount) AS total_web_return_amount,
        COUNT(DISTINCT bill_customer_sk) AS distinct_bill_customers
    FROM joined
    GROUP BY sell_date, ship_mode, credit_rating
)
SELECT
    sell_date,
    ship_mode,
    credit_rating,
    total_net_profit,
    total_catalog_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    distinct_bill_customers,
    SUM(total_net_profit) OVER (
        PARTITION BY ship_mode
        ORDER BY sell_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_profit_by_shipmode
FROM aggregated
ORDER BY sell_date DESC, ship_mode
LIMIT 100
