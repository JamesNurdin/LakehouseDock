WITH
    joined_data AS (
        SELECT DISTINCT
            i.i_category,
            i.i_category_id,
            i.i_brand,
            i.i_brand_id,
            i.i_item_id,
            i.i_product_name,
            s.s_store_name,
            s.s_manager,
            d_sr.d_year AS store_year,
            d_sr.d_month_seq AS store_month,
            sr.sr_return_quantity,
            COALESCE(sr.sr_net_loss, 0) AS store_net_loss,
            COALESCE(cr.cr_net_loss, 0) AS catalog_net_loss,
            COALESCE(wr.wr_net_loss, 0) AS web_net_loss,
            COALESCE(p.p_cost, 0) AS promo_cost,
            cc.cc_class,
            ws.web_country
        FROM
            item i
            LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
            LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
            LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
            LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
            LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
            LEFT JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk

            LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
            LEFT JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
            LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
            LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
            LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
            LEFT JOIN customer_address ca_cr_refunded ON cr.cr_refunded_addr_sk = ca_cr_refunded.ca_address_sk
            LEFT JOIN customer_address ca_cr_returning ON cr.cr_returning_addr_sk = ca_cr_returning.ca_address_sk

            LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
            LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
            LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
            LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
            LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
            LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk

            LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
            LEFT JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
            LEFT JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk

            LEFT JOIN web_site ws ON ws.web_open_date_sk = d_promo_start.d_date_sk
            LEFT JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
            LEFT JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk

            LEFT JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
            LEFT JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
            LEFT JOIN date_dim d_cc_close ON cc.cc_closed_date_sk = d_cc_close.d_date_sk
            LEFT JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
            LEFT JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    ),
    agg_data AS (
        SELECT
            i_category_id,
            i_category,
            i_brand_id,
            i_brand,
            SUM(store_net_loss + catalog_net_loss + web_net_loss) AS total_net_loss,
            SUM(sr_return_quantity) AS total_return_qty,
            COUNT(DISTINCT i_item_id) AS distinct_items,
            AVG(promo_cost) AS avg_promo_cost
        FROM
            joined_data
        WHERE
            store_year = 2001
            AND i_category_id IN (10, 7)
            AND i_brand_id = 5002002
            AND s_manager = 'William Ward'
            AND cc_class = 'Large'
            AND promo_cost >= 50
            AND web_country = 'United States'
        GROUP BY
            i_category_id,
            i_category,
            i_brand_id,
            i_brand
    )
SELECT
    a.i_category_id,
    a.i_category,
    a.i_brand_id,
    a.i_brand,
    a.total_net_loss,
    a.total_return_qty,
    a.distinct_items,
    a.avg_promo_cost,
    ROW_NUMBER() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank,
    SUM(a.total_net_loss) OVER (
        ORDER BY a.total_net_loss DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_loss
FROM
    agg_data a
ORDER BY
    a.total_net_loss DESC
LIMIT 100
