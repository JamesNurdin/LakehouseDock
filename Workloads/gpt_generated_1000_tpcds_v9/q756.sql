WITH combined_data AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_product_name AS product_name,
        d_sv.d_year AS sale_year,
        ss.ss_ticket_number AS ticket_number,
        cs.cs_order_number AS order_number,
        ss.ss_net_profit AS store_net_profit,
        sr.sr_net_loss AS store_return_loss,
        cs.cs_net_profit AS catalog_net_profit,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss,
        (ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0)) AS adj_store_profit,
        (cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0) - COALESCE(wr.wr_net_loss, 0)) AS adj_catalog_profit,
        cd.cd_credit_rating,
        i.i_rec_start_date,
        s.s_state,
        p_store.p_discount_active,
        cp.cp_department,
        cp.cp_type
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_sv ON ss.ss_sold_date_sk = d_sv.d_date_sk
    JOIN time_dim t_sv ON ss.ss_sold_time_sk = t_sv.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN date_dim d_sr_ret ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
    LEFT JOIN time_dim t_sr_ret ON sr.sr_return_time_sk = t_sr_ret.t_time_sk
    LEFT JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p_catalog ON cs.cs_promo_sk = p_catalog.p_promo_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_cs_sold ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    LEFT JOIN time_dim t_cs_sold ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    LEFT JOIN date_dim d_cs_ship ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                                 AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
    LEFT JOIN time_dim t_cr_ret ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN date_dim d_wr_ret ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    LEFT JOIN time_dim t_wr_ret ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    WHERE
        cd.cd_credit_rating IN ('Good', 'High Risk')
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND s.s_state = 'TX'
        AND d_sv.d_year BETWEEN 2001 AND 2002
        AND p_store.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = cp.cp_department
              AND cp2.cp_type = 'A'
        )
)

SELECT
    store_name,
    product_name,
    sale_year,
    SUM(adj_store_profit) AS total_adj_store_profit,
    SUM(store_return_loss) AS total_store_return_loss,
    SUM(adj_catalog_profit) AS total_adj_catalog_profit,
    COUNT(DISTINCT ticket_number) AS store_ticket_cnt,
    COUNT(DISTINCT order_number) AS catalog_order_cnt
FROM combined_data
GROUP BY store_name, product_name, sale_year
HAVING SUM(adj_store_profit) > 0
ORDER BY total_adj_store_profit DESC
LIMIT 100
