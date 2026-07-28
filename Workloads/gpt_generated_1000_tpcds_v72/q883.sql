WITH distinct_returns AS (
    SELECT DISTINCT
        s.s_store_name,
        i.i_brand,
        d_ret.d_year AS return_year,
        r_ret.r_reason_desc
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN reason r_ret ON sr.sr_reason_sk = r_ret.r_reason_sk
),
joined_data AS (
    SELECT
        s.s_store_name,
        i.i_brand,
        p_ss.p_promo_name,
        d_ss.d_year,
        ss.ss_ticket_number,
        ss.ss_net_paid AS store_net_paid,
        cs.cs_net_paid AS catalog_net_paid,
        ws.ws_net_paid AS web_net_paid,
        cr.cr_return_quantity AS catalog_return_qty,
        wr.wr_return_quantity AS web_return_qty,
        r_sr.r_reason_desc AS store_return_reason,
        r_cr.r_reason_desc AS catalog_return_reason,
        r_wr.r_reason_desc AS web_return_reason
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk

    -- Catalog sales and related dimensions
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w_cs ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk

    -- Web sales and related dimensions
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk

    -- Inventory and income band
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    JOIN income_band ib ON hd_ss.hd_income_band_sk = ib.ib_income_band_sk

    -- Promotion date dimensions
    JOIN date_dim d_p_start ON p_ss.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end ON p_ss.p_end_date_sk = d_p_end.d_date_sk

    -- Call center open/close dates
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk

    -- Catalog page start/end dates
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk

    -- Web page creation/access dates
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk

    -- Web site open/close dates
    JOIN date_dim d_ws_open ON wsite.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close ON wsite.web_close_date_sk = d_ws_close.d_date_sk
)
SELECT
    jd.s_store_name,
    jd.i_brand,
    jd.p_promo_name,
    jd.d_year,
    COUNT(DISTINCT jd.ss_ticket_number) AS num_transactions,
    SUM(jd.store_net_paid) AS total_store_net_paid,
    SUM(jd.catalog_net_paid) AS total_catalog_net_paid,
    SUM(jd.web_net_paid) AS total_web_net_paid,
    SUM(COALESCE(jd.catalog_return_qty, 0)) AS total_catalog_return_qty,
    SUM(COALESCE(jd.web_return_qty, 0)) AS total_web_return_qty,
    COUNT(DISTINCT dr.return_year) AS distinct_return_years
FROM joined_data jd
LEFT JOIN distinct_returns dr
    ON dr.s_store_name = jd.s_store_name AND dr.i_brand = jd.i_brand
GROUP BY CUBE (jd.s_store_name, jd.i_brand, jd.p_promo_name, jd.d_year)
ORDER BY jd.s_store_name ASC, jd.i_brand ASC, total_store_net_paid DESC
LIMIT 100
