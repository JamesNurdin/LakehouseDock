WITH joined AS (
    SELECT
        s.s_store_id AS s_store_id,
        s.s_market_manager,
        d_year.d_year AS d_year,
        p.p_promo_name,
        ss.ss_net_paid AS ss_net_paid,
        ss.ss_net_profit AS ss_net_profit,
        sr.sr_return_amt AS sr_return_amt,
        cs.cs_net_paid AS cs_net_paid,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_amount AS cr_return_amount,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_amt AS wr_return_amt,
        inv.inv_quantity_on_hand,
        ib.ib_income_band_sk,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential
    FROM
        store s
        JOIN store_sales ss ON ss.ss_store_sk = s.s_store_sk
        JOIN date_dim d_year ON ss.ss_sold_date_sk = d_year.d_date_sk
        JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                                 AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN date_dim d_return ON sr.sr_returned_date_sk = d_return.d_date_sk
        LEFT JOIN time_dim t_return ON sr.sr_return_time_sk = t_return.t_time_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d_year.d_date_sk
        LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        -- catalog side
        JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
        JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                    AND cr.cr_item_sk = cs.cs_item_sk
        -- web side
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site webs ON ws.ws_web_site_sk = webs.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    WHERE
        s.s_market_manager = 'James Irvin'
        AND cp.cp_type = 'A'
        AND p.p_discount_active = 'Y'
        AND d_year.d_year = 2001
        AND inv.inv_quantity_on_hand > 0
        AND wr.wr_fee > 10
)
SELECT
    s_store_id,
    d_year,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(wr_return_amt) AS total_web_returns,
    AVG(ss_net_profit) AS avg_store_profit
FROM joined
GROUP BY s_store_id, d_year
HAVING
    SUM(ss_net_paid) > 10000
    AND SUM(cs_net_paid) > 5000
    AND SUM(ws_net_paid) > 5000
ORDER BY total_store_sales DESC
LIMIT 100
