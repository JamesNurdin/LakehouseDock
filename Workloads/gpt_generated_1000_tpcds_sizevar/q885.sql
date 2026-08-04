WITH cs_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_warehouse_sk,
        d_sold.d_year,
        t_sold.t_hour,
        i.i_category,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        cc.cc_name,
        cp.cp_department,
        w.w_city,
        s.s_store_name
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE cs.cs_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
),
ws_base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_warehouse_sk,
        d2.d_year AS ws_year,
        t2.t_hour AS ws_hour,
        i2.i_category AS ws_category,
        hd2.hd_income_band_sk AS ws_hd_income,
        ib2.ib_upper_bound AS ws_income_upper,
        wp.wp_type,
        web.web_name,
        w2.w_city AS ws_warehouse_city,
        wr.wr_return_quantity
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
    JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
)
SELECT
    cs.cs_order_number,
    cs.d_year,
    cs.t_hour,
    cs.i_category,
    cs.cc_name,
    cs.cp_department,
    cs.w_city AS catalog_warehouse_city,
    ws.ws_year,
    ws.ws_hour,
    ws.ws_category,
    ws.wp_type,
    ws.web_name,
    ws.ws_warehouse_city,
    CASE WHEN cs.cs_net_paid > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS payment_flag,
    cr_cnt.return_count,
    intersect_cnt.intersect_orders,
    except_cnt.cs_minus_returns
FROM cs_base cs
JOIN ws_base ws ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN LATERAL (
    SELECT COUNT(*) AS return_count
    FROM catalog_returns cr
    WHERE cr.cr_order_number = cs.cs_order_number
) cr_cnt ON true
CROSS JOIN (
    SELECT COUNT(*) AS intersect_orders
    FROM (
        SELECT cs_order_number FROM cs_base
        INTERSECT
        SELECT ws_order_number FROM ws_base
    ) t
) intersect_cnt
CROSS JOIN (
    SELECT COUNT(*) AS cs_minus_returns
    FROM (
        SELECT cs_order_number FROM cs_base
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ) t
) except_cnt
ORDER BY cs.cs_order_number, ws.ws_order_number
OFFSET 0 LIMIT 100
