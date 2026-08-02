WITH base AS (
    SELECT
        s.s_store_name,
        w.w_warehouse_name,
        i.i_item_id,
        i.i_current_price,
        i.i_color,
        cd.cd_education_status,
        cd.cd_dep_count,
        w.w_state,
        ws.ws_ext_sales_price,
        sr.sr_return_amt,
        cr.cr_return_amount,
        ws.ws_quantity,
        p.p_discount_active
    FROM
        web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_return_time_sk = td.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_returned_time_sk = td.t_time_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                             AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        i.i_current_price > 100
        AND i.i_color = 'Red'
        AND cd.cd_education_status = '4 yr Degree'
        AND cd.cd_dep_count >= 2
        AND w.w_state = 'CA'
        AND i.i_rec_start_date <= DATE '2020-01-01'
        AND cc.cc_rec_end_date >= DATE '2005-01-01'
        AND ws.ws_ext_sales_price > (
            SELECT AVG(ws2.ws_ext_sales_price)
            FROM web_sales ws2
            WHERE ws2.ws_item_sk = ws.ws_item_sk
        )
)
SELECT
    s_store_name,
    i_item_id,
    SUM(total_sales) AS sum_total_sales,
    AVG(total_sales) AS avg_total_sales,
    COUNT(*) AS cnt_rows,
    MIN(total_sales) AS min_total_sales,
    MAX(total_sales) AS max_total_sales,
    GROUPING(s_store_name) AS grp_store,
    GROUPING(i_item_id) AS grp_item
FROM (
    SELECT
        s_store_name,
        i_item_id,
        ws_ext_sales_price + sr_return_amt + cr_return_amount AS total_sales
    FROM base
) t
GROUP BY GROUPING SETS ((s_store_name, i_item_id), (s_store_name), (i_item_id), ())
ORDER BY sum_total_sales DESC
OFFSET 0 LIMIT 100
