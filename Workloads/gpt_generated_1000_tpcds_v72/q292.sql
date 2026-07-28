WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        d.d_date,
        cc.cc_name,
        cc.cc_class,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_email,
        w.w_warehouse_name,
        ca.ca_state,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        ss.ss_net_paid            AS store_net_paid,
        ss.ss_net_profit          AS store_net_profit,
        sr.sr_net_loss            AS store_net_loss,
        ws.ws_net_paid            AS web_net_paid,
        ws.ws_net_profit          AS web_net_profit,
        ws.ws_quantity            AS ws_quantity,
        wr.wr_net_loss            AS web_net_loss,
        cr.cr_net_loss            AS catalog_net_loss,
        inv.inv_quantity_on_hand  AS inv_quantity_on_hand,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status
    FROM
        date_dim d
        LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
        LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
            AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
            AND we.web_open_date_sk = d.d_date_sk
), aggregated AS (
    SELECT
        d_year,
        d_quarter_name,
        promo_status,
        SUM(store_net_paid)                     AS total_store_paid,
        SUM(web_net_paid)                       AS total_web_paid,
        SUM(COALESCE(store_net_profit, 0) + COALESCE(web_net_profit, 0)) AS total_profit
    FROM
        joined_data
    WHERE
        d_year BETWEEN 2010 AND 2020
        AND cc_class IN ('large', 'medium')
        AND p_channel_email = 'Y'
        AND ca_state = 'CA'
        AND inv_quantity_on_hand > 0
        AND ws_quantity > 0
    GROUP BY GROUPING SETS (
        (d_year, d_quarter_name, promo_status),
        (d_year, promo_status),
        (promo_status),
        ()
    )
)
SELECT
    d_year,
    d_quarter_name,
    promo_status,
    total_store_paid,
    total_web_paid,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM
    aggregated
ORDER BY
    profit_rank,
    d_year,
    d_quarter_name
