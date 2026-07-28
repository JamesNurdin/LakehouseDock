WITH
    sales_data AS (
        SELECT
            ss.ss_store_sk,
            ss.ss_promo_sk,
            d_sold.d_year AS d_year,
            ss.ss_ext_sales_price AS sales_amount,
            0.0 AS return_amount,
            s.s_store_name,
            p.p_promo_name
        FROM store_sales ss
        INNER JOIN date_dim d_sold
            ON ss.ss_sold_date_sk = d_sold.d_date_sk
        INNER JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        INNER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN time_dim t
            ON ss.ss_sold_time_sk = t.t_time_sk
        INNER JOIN customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        INNER JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        INNER JOIN web_page wp
            ON wp.wp_creation_date_sk = d_sold.d_date_sk
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_refunded_customer_sk = ss.ss_customer_sk
        )
    ),
    returns_data AS (
        SELECT
            cs.cs_promo_sk,
            d_ret.d_year AS d_year,
            0.0 AS sales_amount,
            cr.cr_net_loss AS return_amount,
            cp.cp_catalog_page_id,
            r.r_reason_desc,
            sm.sm_type,
            cc.cc_name,
            d_cp_start.d_year AS cp_start_year,
            d_cp_end.d_year AS cp_end_year
        FROM catalog_returns cr
        INNER JOIN catalog_sales cs
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        INNER JOIN date_dim d_ret
            ON cr.cr_returned_date_sk = d_ret.d_date_sk
        INNER JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        INNER JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        INNER JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        INNER JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN date_dim d_cp_start
            ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        INNER JOIN date_dim d_cp_end
            ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    )
SELECT
    sd.s_store_name AS store_name,
    sd.p_promo_name AS promotion_name,
    sd.d_year AS year,
    SUM(sd.sales_amount) AS total_sales,
    SUM(rd.return_amount) AS total_return_loss,
    SUM(sd.sales_amount) - SUM(rd.return_amount) AS net_contribution
FROM sales_data sd
LEFT JOIN returns_data rd
    ON rd.cs_promo_sk = sd.ss_promo_sk
    AND rd.d_year = sd.d_year
GROUP BY
    sd.s_store_name,
    sd.p_promo_name,
    sd.d_year
ORDER BY net_contribution DESC
LIMIT 100
