WITH d_year AS (
        SELECT d_date_sk, d_date, d_year
        FROM date_dim
        WHERE d_year = 2001
    )
SELECT
    s.s_store_id,
    d_ss.d_date,
    s.s_state,
    w_ws.w_zip,
    SUM(ss.ss_net_profit)                         AS store_net_profit,
    SUM(ws.ws_net_profit)                         AS web_net_profit,
    SUM(cr.cr_net_loss)                           AS catalog_net_loss,
    SUM(wr.wr_net_loss)                           AS web_return_net_loss,
    CASE
        WHEN (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) > 5000 THEN 'HIGH'
        WHEN (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) > 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END                                            AS profit_level,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_id
        ORDER BY (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) DESC
    )                                             AS profit_rank
FROM store_sales ss
JOIN d_year d_ss               ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss              ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer c_ss              ON ss.ss_customer_sk = c_ss.c_customer_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN store s                    ON ss.ss_store_sk = s.s_store_sk
-- store closed date (dimension)                              
JOIN date_dim d_sclosed          ON s.s_closed_date_sk = d_sclosed.d_date_sk

-- Catalog Returns and its dimension chain
CROSS JOIN d_year d_cr          -- reuse the same filtered date set for the return date
JOIN catalog_returns cr         ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr               ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN call_center cc              ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cr             ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr              ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN reason r_cr                 ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN customer c_refunded        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer c_returning        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk

-- Web Sales and its dimension chain
CROSS JOIN d_year d_ws          -- filtered date for web sales
JOIN web_sales ws                ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws               ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer c_ws_bill          ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
JOIN customer c_ws_ship          ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
JOIN customer_demographics cd_ws_ship ON ws.ws_ship_cdemo_sk = cd_ws_ship.cd_demo_sk
JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
JOIN web_page wp                 ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm_ws             ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws              ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk

-- Web Returns and its dimension chain
JOIN web_returns wr              ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr               ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr               ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN reason r_wr                 ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer c_wr_refunded      ON wr.wr_refunded_customer_sk = c_wr_refunded.c_customer_sk
JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN customer c_wr_returning      ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
JOIN web_page wp_wr              ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

-- Inventory linked to the same warehouse used by web sales
JOIN inventory inv               ON inv.inv_warehouse_sk = w_ws.w_warehouse_sk
                                 AND inv.inv_date_sk = d_ss.d_date_sk

WHERE d_ss.d_year = 2001                                   -- filter 1
  AND s.s_state = 'TX'                                    -- filter 2
  AND w_ws.w_zip = '42477'                                 -- filter 3
  AND cr.cr_return_tax > 20.0                              -- filter 4
  AND ws.ws_net_profit > 0.0                               -- filter 5
  AND inv.inv_quantity_on_hand > 1000                      -- filter 6
  AND cd_ss.cd_gender = 'M'                                -- filter 7
GROUP BY s.s_store_id, d_ss.d_date, s.s_state, w_ws.w_zip
ORDER BY profit_rank, s.s_store_id
