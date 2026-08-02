WITH sr_reason AS (
    SELECT sr.*, r.r_reason_desc
    FROM store_returns sr
    FULL OUTER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),

store_web_union AS (
    SELECT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        td.t_hour,
        r_cr.r_reason_desc AS return_reason,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca.ca_city,
        ca.ca_location_type,
        s.s_store_name,
        wp.wp_url,
        SUM(ss.ss_net_paid)          AS total_net_paid,
        SUM(ss.ss_net_profit)        AS total_net_profit,
        SUM(sr_reason.sr_refunded_cash) AS total_refunded_cash_sr,
        SUM(sr_reason.sr_net_loss)      AS total_net_loss_sr,
        SUM(cr.cr_return_amount)        AS total_return_amount_cr,
        SUM(cr.cr_net_loss)             AS total_net_loss_cr,
        SUM(wr.wr_refunded_cash)        AS total_refunded_cash_wr,
        SUM(wr.wr_net_loss)             AS total_net_loss_wr,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM call_center cc
    JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_sold_time_sk = td.t_time_sk
       AND ss.ss_customer_sk = c.c_customer_sk
       AND ss.ss_cdemo_sk = cd.cd_demo_sk
       AND ss.ss_hdemo_sk = hd.hd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN sr_reason ON sr_reason.sr_item_sk = i.i_item_sk
        AND sr_reason.sr_return_time_sk = td.t_time_sk
        AND sr_reason.sr_customer_sk = c.c_customer_sk
        AND sr_reason.sr_cdemo_sk = cd.cd_demo_sk
        AND sr_reason.sr_hdemo_sk = hd.hd_demo_sk
        AND sr_reason.sr_addr_sk = ca.ca_address_sk
        AND sr_reason.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE
        ca.ca_city = 'Lipscomb County'
        AND i.i_category = 'Electronics'
        AND td.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
              AND wr2.wr_returned_time_sk = td.t_time_sk
              AND wr2.wr_refunded_cash > 50
        )
    GROUP BY ROLLUP (
        cc.cc_call_center_id,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        td.t_hour,
        r_cr.r_reason_desc,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca.ca_city,
        ca.ca_location_type,
        s.s_store_name,
        wp.wp_url
    )
),

store_web_distinct AS (
    SELECT DISTINCT
        cc.cc_call_center_id,
        w.w_warehouse_name,
        NULL AS i_item_id,
        i.i_category,
        NULL AS i_brand,
        NULL AS t_hour,
        NULL AS return_reason,
        NULL AS c_customer_id,
        NULL AS cd_gender,
        NULL AS hd_buy_potential,
        NULL AS ca_city,
        NULL AS ca_location_type,
        NULL AS s_store_name,
        NULL AS wp_url,
        0 AS total_net_paid,
        0 AS total_net_profit,
        0 AS total_refunded_cash_sr,
        0 AS total_net_loss_sr,
        0 AS total_return_amount_cr,
        0 AS total_net_loss_cr,
        0 AS total_refunded_cash_wr,
        0 AS total_net_loss_wr,
        0 AS distinct_tickets
    FROM call_center cc
    JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE i.i_category = 'Electronics'
)

SELECT
    u.cc_call_center_id,
    u.w_warehouse_name,
    u.i_item_id,
    u.i_category,
    u.i_brand,
    u.t_hour,
    u.return_reason,
    u.c_customer_id,
    u.cd_gender,
    u.hd_buy_potential,
    u.ca_city,
    u.ca_location_type,
    u.s_store_name,
    u.wp_url,
    u.total_net_paid,
    u.total_net_profit,
    u.total_refunded_cash_sr,
    u.total_net_loss_sr,
    u.total_return_amount_cr,
    u.total_net_loss_cr,
    u.total_refunded_cash_wr,
    u.total_net_loss_wr,
    u.distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY u.cc_call_center_id ORDER BY u.total_net_profit DESC) AS profit_rank,
    CASE
        WHEN u.total_net_profit > (
            SELECT AVG(total_net_profit) FROM store_web_union su WHERE su.cc_call_center_id = u.cc_call_center_id
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM (
    SELECT * FROM store_web_union
    UNION ALL
    SELECT * FROM store_web_distinct
) u
ORDER BY u.cc_call_center_id, profit_rank
LIMIT 100
