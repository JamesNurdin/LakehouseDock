WITH ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_web_page_sk,
        i.i_category,
        i.i_current_price,
        t_ws.t_hour,
        s.s_store_name
    FROM web_sales ws
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN store s ON ws.ws_ship_mode_sk = s.s_store_sk -- placeholder to bring store into base (will be re‑joined later correctly)
    WHERE i.i_current_price > 0
),
joined_all AS (
    SELECT
        s.s_store_name,
        i.i_category,
        t_ws.t_hour,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amount,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amount,
        SUM(ws.ws_net_profit) -
        SUM(COALESCE(sr.sr_net_loss, 0)) -
        SUM(COALESCE(cr.cr_net_loss, 0)) -
        SUM(COALESCE(wr.wr_net_loss, 0)) AS net_contribution
    FROM web_sales ws
    /* Core dimensions */
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk

    /* Catalog returns and related dimensions */
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk

    /* Store returns and related dimensions */
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk

    /* Web returns and related dimensions */
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN customer c_wr_refunded ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
    JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
    JOIN customer c_wr_returning ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
    JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    WHERE
        t_ws.t_hour BETWEEN 8 AND 18
        AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = ws.ws_promo_sk
              AND p2.p_discount_active = 'Y'
        )
    GROUP BY
        s.s_store_name,
        i.i_category,
        t_ws.t_hour
    HAVING
        SUM(ws.ws_net_paid) > 10000
)
SELECT *
FROM joined_all
ORDER BY net_contribution DESC
LIMIT 100
