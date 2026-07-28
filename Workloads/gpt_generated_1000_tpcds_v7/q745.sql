WITH base AS (
    SELECT
        s.s_store_id,
        d.d_year,
        cs.cs_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cr.cr_net_loss
    FROM
        date_dim d
        INNER JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        INNER JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        INNER JOIN item i ON sr.sr_item_sk = i.i_item_sk
        INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        INNER JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
        INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        INNER JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        INNER JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        d.d_year = 2001
        AND s.s_state = 'CA'
        AND sm.sm_carrier = 'AIRBORNE'
        AND cp.cp_type = 'monthly'
),
per_store AS (
    SELECT
        s_store_id,
        d_year,
        SUM(cs_net_profit) AS total_profit,
        SUM(sr_net_loss) AS total_store_loss,
        SUM(wr_net_loss) AS total_web_loss,
        SUM(cr_net_loss) AS total_catalog_loss
    FROM
        base
    GROUP BY
        s_store_id,
        d_year
)
SELECT
    s_store_id,
    d_year,
    total_profit - (total_store_loss + total_web_loss + total_catalog_loss) AS net_total,
    total_profit,
    total_store_loss,
    total_web_loss,
    total_catalog_loss
FROM
    per_store
WHERE
    (total_profit - (total_store_loss + total_web_loss + total_catalog_loss)) > 10000
ORDER BY
    net_total DESC
