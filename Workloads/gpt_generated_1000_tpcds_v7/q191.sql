WITH base AS (
    SELECT
        d.d_year,
        cp.cp_catalog_page_id,
        wp.wp_web_page_id,
        w.w_warehouse_name,
        s.s_store_name,
        r.r_reason_desc,
        cs.cs_net_profit               AS catalog_net_profit,
        cr.cr_net_loss                 AS catalog_return_loss,
        ws.ws_net_profit               AS web_net_profit,
        wr.wr_net_loss                 AS web_return_loss,
        sr.sr_net_loss                 AS store_return_loss
    FROM catalog_sales cs
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN time_dim t               ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr    ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN store s             ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r            ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr      ON cr.cr_order_number   = cs.cs_order_number
                               AND cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws            ON ws.ws_sold_date_sk  = d.d_date_sk
                               AND ws.ws_sold_time_sk  = t.t_time_sk
    JOIN web_page wp             ON ws.ws_web_page_sk   = wp.wp_web_page_sk
    LEFT JOIN web_returns wr    ON wr.wr_order_number   = ws.ws_order_number
                               AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'first'
      AND w.w_state = 'CA'
      AND r.r_reason_desc = 'Customer not satisfied'
      AND wp.wp_autogen_flag = 'N'
)
SELECT
    d_year,
    cp_catalog_page_id,
    wp_web_page_id,
    w_warehouse_name,
    s_store_name,
    SUM(catalog_net_profit)   AS total_catalog_profit,
    SUM(catalog_return_loss)  AS total_catalog_return_loss,
    SUM(web_net_profit)       AS total_web_profit,
    SUM(web_return_loss)      AS total_web_return_loss,
    SUM(store_return_loss)    AS total_store_return_loss,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(catalog_net_profit) + SUM(web_net_profit) DESC) AS profit_rank
FROM base
GROUP BY d_year, cp_catalog_page_id, wp_web_page_id, w_warehouse_name, s_store_name
ORDER BY profit_rank
LIMIT 100
