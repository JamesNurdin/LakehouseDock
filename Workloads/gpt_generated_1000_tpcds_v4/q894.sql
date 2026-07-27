/* goal: Calculate total net profit per promotion across sales and returns channels, categorize profit levels, rank promotions, and compare against the overall average profit while applying multiple business filters */
WITH base AS (
    SELECT
        p.p_promo_id,
        p.p_discount_active,
        w.w_state,
        cc.cc_state,
        sm.sm_type,
        td.t_hour,
        ca.ca_zip,
        hd.hd_income_band_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit          AS cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_net_loss            AS cr_net_loss,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit          AS ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss            AS sr_net_loss,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit          AS ws_net_profit,
        wr.wr_return_quantity,
        wr.wr_net_loss            AS wr_net_loss
    FROM tpcds.time_dim td
    /* store channel */
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_ticket_number   = ss.ss_ticket_number
        AND sr.sr_item_sk         = ss.ss_item_sk
    /* catalog channel */
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_order_number    = cs.cs_order_number
        AND cr.cr_item_sk         = cs.cs_item_sk
    /* web channel */
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
        AND wr.wr_order_number    = ws.ws_order_number
        AND wr.wr_item_sk         = ws.ws_item_sk
    /* shared dimension tables */
    JOIN tpcds.promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
        AND p.p_promo_sk = ss.ss_promo_sk
        AND p.p_promo_sk = ws.ws_promo_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
        AND w.w_warehouse_sk = cr.cr_warehouse_sk
        AND w.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
        AND sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
        AND sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN tpcds.call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
        AND cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
        AND wp.wp_web_page_sk = wr.wr_web_page_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
        AND hd.hd_demo_sk = sr.sr_hdemo_sk
        AND hd.hd_demo_sk = cs.cs_bill_hdemo_sk
        AND hd.hd_demo_sk = cs.cs_ship_hdemo_sk
        AND hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
        AND hd.hd_demo_sk = cr.cr_returning_hdemo_sk
        AND hd.hd_demo_sk = ws.ws_bill_hdemo_sk
        AND hd.hd_demo_sk = ws.ws_ship_hdemo_sk
        AND hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
        AND hd.hd_demo_sk = wr.wr_returning_hdemo_sk
    JOIN tpcds.customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
        AND ca.ca_address_sk = sr.sr_addr_sk
        AND ca.ca_address_sk = cs.cs_bill_addr_sk
        AND ca.ca_address_sk = cs.cs_ship_addr_sk
        AND ca.ca_address_sk = cr.cr_refunded_addr_sk
        AND ca.ca_address_sk = cr.cr_returning_addr_sk
        AND ca.ca_address_sk = ws.ws_bill_addr_sk
        AND ca.ca_address_sk = ws.ws_ship_addr_sk
        AND ca.ca_address_sk = wr.wr_refunded_addr_sk
        AND ca.ca_address_sk = wr.wr_returning_addr_sk
    WHERE
        p.p_discount_active = 'Y'
        AND w.w_state = 'CA'
        AND cc.cc_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND td.t_hour BETWEEN 9 AND 17
        AND ca.ca_zip LIKE '9%'
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND cs.cs_quantity > 5
),
agg AS (
    SELECT
        p_promo_id,
        SUM(cs_net_profit) AS cs_profit,
        SUM(ss_net_profit) AS ss_profit,
        SUM(ws_net_profit) AS ws_profit,
        SUM(cr_net_loss)   AS cr_loss,
        SUM(sr_net_loss)   AS sr_loss,
        SUM(wr_net_loss)   AS wr_loss
    FROM base
    GROUP BY p_promo_id
)
SELECT
    a.p_promo_id,
    (a.cs_profit + a.ss_profit + a.ws_profit - a.cr_loss - a.sr_loss - a.wr_loss) AS total_profit,
    CASE
        WHEN (a.cs_profit + a.ss_profit + a.ws_profit - a.cr_loss - a.sr_loss - a.wr_loss) > 100000 THEN 'HIGH'
        WHEN (a.cs_profit + a.ss_profit + a.ws_profit - a.cr_loss - a.sr_loss - a.wr_loss) > 0      THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (ORDER BY (a.cs_profit + a.ss_profit + a.ws_profit - a.cr_loss - a.sr_loss - a.wr_loss) DESC) AS profit_rank,
    (
        SELECT AVG(t.total_profit)
        FROM (
            SELECT (cs_profit + ss_profit + ws_profit - cr_loss - sr_loss - wr_loss) AS total_profit
            FROM agg
        ) t
    ) AS avg_total_profit
FROM agg a
WHERE (a.cs_profit + a.ss_profit + a.ws_profit - a.cr_loss - a.sr_loss - a.wr_loss) > (
        SELECT AVG(t.total_profit)
        FROM (
            SELECT (cs_profit + ss_profit + ws_profit - cr_loss - sr_loss - wr_loss) AS total_profit
            FROM agg
        ) t
    )
ORDER BY total_profit DESC
LIMIT 100
