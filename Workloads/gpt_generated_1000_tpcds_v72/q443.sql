WITH joined_data AS (
    SELECT
        s.s_store_name,
        t.t_hour,
        cd.cd_gender,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions,
        (SELECT MAX(p2.p_cost) FROM promotion p2) AS max_promo_cost
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    
    -- catalog side
    JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_returned_time_sk = t.t_time_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    
    -- store returns side
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    
    -- web side
    JOIN web_returns wr ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE
    cc.cc_division_name = 'anti'
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND cd.cd_credit_rating = 'Good'
GROUP BY
    s.s_store_name,
    t.t_hour,
    cd.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING
    SUM(ss.ss_net_profit) > 10000
ORDER BY
    store_net_profit DESC
LIMIT 100
)
SELECT * FROM joined_data
