WITH base_join AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_number,
        cp.cp_type,
        sm.sm_type,
        w.w_warehouse_name,
        p.p_promo_name,
        p.p_discount_active,
        r.r_reason_desc,
        wp.wp_type,
        web_site.web_name,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        wr.wr_return_amt
    FROM
        date_dim d
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk AND wp.wp_access_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
            AND ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
            AND ws.ws_promo_sk = p.p_promo_sk
            AND ws.ws_web_page_sk = wp.wp_web_page_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_site web_site ON ws.ws_web_site_sk = web_site.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_item_sk = ws.ws_item_sk
            AND wr.wr_web_page_sk = wp.wp_web_page_sk
            AND wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_returned_date_sk = d.d_date_sk
            AND wr.wr_returned_time_sk = t.t_time_sk
    WHERE
        d.d_year = 2001
        AND cp.cp_catalog_number = 12
        AND cc.cc_state = 'CA'
        AND sm.sm_type = 'AIR'
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        cc_name,
        cc_state,
        cp_catalog_number,
        cp_type,
        sm_type,
        w_warehouse_name,
        p_promo_name,
        p_discount_active,
        r_reason_desc,
        wp_type,
        web_name,
        SUM(cs_net_paid) AS total_sales,
        SUM(ws_net_paid) AS total_web_sales,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(wr_return_amt, 0)) AS total_web_return_amount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_quantity) AS avg_quantity,
        MIN(cs_sales_price) AS min_sales_price,
        MAX(cs_sales_price) AS max_sales_price,
        (SELECT COUNT(DISTINCT p2.p_promo_name) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS total_active_promos
    FROM
        base_join
    GROUP BY
        d_year,
        d_month_seq,
        cc_name,
        cc_state,
        cp_catalog_number,
        cp_type,
        sm_type,
        w_warehouse_name,
        p_promo_name,
        p_discount_active,
        r_reason_desc,
        wp_type,
        web_name
    HAVING
        SUM(cs_net_paid) > 100000
        AND COUNT(DISTINCT cs_order_number) >= 10
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.cc_name,
    a.cc_state,
    a.cp_catalog_number,
    a.cp_type,
    a.sm_type,
    a.w_warehouse_name,
    a.p_promo_name,
    a.p_discount_active,
    a.r_reason_desc,
    a.wp_type,
    a.web_name,
    a.total_sales,
    a.total_web_sales,
    a.total_return_amount,
    a.total_web_return_amount,
    a.distinct_orders,
    a.avg_quantity,
    a.min_sales_price,
    a.max_sales_price,
    a.total_active_promos,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM
    agg a
ORDER BY
    a.total_sales DESC,
    a.d_year,
    a.d_month_seq
LIMIT 100
