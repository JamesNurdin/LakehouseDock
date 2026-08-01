WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        s.s_store_name            AS s_store_name,
        d_sales.d_quarter_name    AS d_quarter_name,
        -- additional columns can be selected if needed
        CASE WHEN sr.sr_net_loss > 10000 THEN 'HIGH' ELSE 'LOW' END AS store_return_loss_flag
    FROM store_sales ss
    JOIN date_dim d_sales            ON ss.ss_sold_date_sk   = d_sales.d_date_sk
    JOIN time_dim t_sales            ON ss.ss_sold_time_sk   = t_sales.t_time_sk
    JOIN store s                     ON ss.ss_store_sk       = s.s_store_sk
    JOIN customer c                  ON ss.ss_customer_sk    = c.c_customer_sk
    JOIN customer_demographics cd    ON ss.ss_cdemo_sk       = cd.cd_demo_sk
    JOIN customer_address ca        ON ss.ss_addr_sk        = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND sr.sr_store_sk       = s.s_store_sk
    LEFT JOIN date_dim d_store_ret   ON sr.sr_returned_date_sk = d_store_ret.d_date_sk
    LEFT JOIN time_dim t_store_ret   ON sr.sr_return_time_sk   = t_store_ret.t_time_sk
    LEFT JOIN reason r_sr            ON sr.sr_reason_sk        = r_sr.r_reason_sk
    JOIN catalog_returns cr
        ON cr.cr_item_sk = ss.ss_item_sk
    JOIN date_dim d_catalog_ret      ON cr.cr_returned_date_sk = d_catalog_ret.d_date_sk
    JOIN time_dim t_catalog_ret      ON cr.cr_returned_time_sk = t_catalog_ret.t_time_sk
    JOIN call_center cc              ON cr.cr_call_center_sk   = cc.cc_call_center_sk
    JOIN catalog_page cp              ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cc_open          ON cc.cc_open_date_sk    = d_cc_open.d_date_sk
    JOIN date_dim d_cc_closed        ON cc.cc_closed_date_sk  = d_cc_closed.d_date_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_web_ret          ON wr.wr_returned_date_sk = d_web_ret.d_date_sk
    JOIN time_dim t_web_ret          ON wr.wr_returned_time_sk = t_web_ret.t_time_sk
    JOIN reason r_wr                ON wr.wr_reason_sk        = r_wr.r_reason_sk
    JOIN web_site ws                 ON ws.web_open_date_sk   = d_sales.d_date_sk
    JOIN date_dim d_web_close        ON ws.web_close_date_sk  = d_web_close.d_date_sk
)
SELECT
    s_store_name,
    d_quarter_name,
    SUM(ss_net_paid)               AS total_sales,
    SUM(ss_net_profit)             AS total_profit,
    SUM(sr_net_loss)               AS total_store_return_loss,
    SUM(cr_net_loss)               AS total_catalog_return_loss,
    SUM(wr_net_loss)               AS total_web_return_loss,
    CASE WHEN SUM(sr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY SUM(ss_net_paid) DESC) AS rn
FROM base
GROUP BY s_store_name, d_quarter_name
ORDER BY total_sales DESC
LIMIT 100
