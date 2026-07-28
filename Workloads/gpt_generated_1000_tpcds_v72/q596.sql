WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_date,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        cs.cs_order_number        AS order_number,
        cs.cs_net_profit          AS cs_net_profit,
        ss.ss_net_profit          AS ss_net_profit,
        ws.ws_net_profit          AS ws_net_profit,
        COALESCE(cr.cr_net_loss, 0)          AS cr_net_loss,
        (COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(cr.cr_net_loss, 0)) AS total_net_profit,
        sm.sm_carrier,
        we.web_state,
        p.p_discount_active,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name,
        r.r_reason_desc
    FROM catalog_sales cs
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t                     ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib                ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r                 ON cr.cr_reason_sk = r.r_reason_sk
    -- Store sales and related dimensions
    JOIN store_sales ss                ON ss.ss_sold_date_sk = d.d_date_sk
                                      AND ss.ss_item_sk = i.i_item_sk
    JOIN store s                       ON ss.ss_store_sk = s.s_store_sk
    -- Store returns (optional, left‑joined)
    LEFT JOIN store_returns sr         ON sr.sr_returned_date_sk = d.d_date_sk
                                      AND sr.sr_item_sk = i.i_item_sk
                                      AND sr.sr_store_sk = s.s_store_sk
                                      AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr              ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- Web sales and related dimensions
    JOIN web_sales ws                  ON ws.ws_sold_date_sk = d.d_date_sk
                                      AND ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp                   ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we                   ON ws.ws_web_site_sk = we.web_site_sk
    -- Inventory (left‑joined, may be missing for some dates/items)
    LEFT JOIN inventory inv            ON inv.inv_date_sk = d.d_date_sk
                                      AND inv.inv_item_sk = i.i_item_sk
                                      AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND sm.sm_carrier = 'USPS'
      AND we.web_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    jd.d_year,
    jd.d_date,
    jd.i_item_sk,
    jd.i_product_name,
    jd.i_brand,
    jd.total_net_profit,
    jd.sm_carrier,
    jd.web_state,
    jd.ca_city,
    jd.cd_gender,
    jd.hd_buy_potential,
    jd.ib_lower_bound,
    jd.ib_upper_bound,
    jd.s_store_name,
    jd.r_reason_desc,
    DENSE_RANK() OVER (PARTITION BY jd.d_year ORDER BY jd.total_net_profit DESC) AS profit_rank
FROM joined_data jd
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_returns cr_sub WHERE cr_sub.cr_order_number = jd.order_number
)
ORDER BY jd.d_year, profit_rank ASC, jd.total_net_profit DESC
LIMIT 100
