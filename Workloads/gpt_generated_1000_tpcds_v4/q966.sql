WITH deep_join AS (
    SELECT
        d_sold.d_year AS sale_year,
        c.c_customer_id,
        cs.cs_order_number,
        ws.ws_order_number,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        cr.cr_net_loss,
        wr.wr_net_loss,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_cs_sold
        ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    JOIN date_dim d_ws_open
        ON we.web_open_date_sk = d_ws_open.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- additional aliases of date_dim for ship dates
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    -- additional aliases of time_dim for other timestamps
    JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN time_dim t_ss_sold
        ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
    JOIN time_dim t_wr_returned
        ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
    LEFT JOIN time_dim t_cr_returned
        ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
)
SELECT
    sale_year,
    c_customer_id,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(COALESCE(cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(wr_net_loss, 0)) AS total_web_return_loss,
    COUNT(DISTINCT CASE WHEN catalog_return_reason IS NOT NULL THEN cs_order_number END) AS catalog_returns_count,
    COUNT(DISTINCT CASE WHEN web_return_reason IS NOT NULL THEN ws_order_number END) AS web_returns_count
FROM deep_join
GROUP BY sale_year, c_customer_id
ORDER BY total_catalog_sales DESC
LIMIT 20
