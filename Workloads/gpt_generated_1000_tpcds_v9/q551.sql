WITH joined AS (
    SELECT
        cc.cc_name,
        cc.cc_mkt_id,
        cc.cc_rec_start_date,
        cc.cc_rec_end_date,
        i.i_item_id,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        p.p_promo_name,
        p.p_discount_active,
        sm.sm_type,
        sm.sm_contract,
        w.w_warehouse_name,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        td.t_hour,
        td.t_am_pm,
        wp.wp_url,
        wp.wp_image_count,
        wp.wp_rec_start_date,
        wp.wp_rec_end_date,
        web.web_name,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    WHERE
        cc.cc_rec_start_date >= DATE '2001-01-01'
        AND cc.cc_rec_end_date <= DATE '2001-12-31'
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_rec_end_date <= DATE '2005-12-31'
        AND wp.wp_rec_start_date = DATE '2000-09-03'
        AND wp.wp_rec_end_date = DATE '2001-09-02'
),
aggregated AS (
    SELECT
        cc_name,
        i_category,
        p_promo_name,
        sm_type,
        t_hour,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_net_profit) AS avg_catalog_profit,
        MAX(cs_ext_sales_price) AS max_catalog_sale,
        MIN(ws_ext_sales_price) AS min_web_sale
    FROM joined
    GROUP BY
        cc_name,
        i_category,
        p_promo_name,
        sm_type,
        t_hour
)
SELECT
    cc_name,
    i_category,
    p_promo_name,
    sm_type,
    t_hour,
    total_catalog_sales,
    total_web_sales,
    total_return_amount,
    distinct_orders,
    avg_catalog_profit,
    max_catalog_sale,
    min_web_sale,
    (total_catalog_sales + total_web_sales - total_return_amount) AS net_sales,
    SUM(total_catalog_sales + total_web_sales - total_return_amount) OVER (
        PARTITION BY cc_name
        ORDER BY i_category
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_net_sales
FROM aggregated
ORDER BY total_catalog_sales DESC
LIMIT 100
