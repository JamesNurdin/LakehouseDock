WITH diff_set AS (
        SELECT ss_ticket_number
        FROM store_sales
        EXCEPT
        SELECT wr_order_number
        FROM web_returns
    ),
    intersect_set AS (
        SELECT i_item_id
        FROM item
        INTERSECT
        SELECT p_promo_id
        FROM promotion
    )
SELECT
    d_sales.d_year,
    ws.web_name,
    cc.cc_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
    SUM(ss.ss_ext_sales_price) AS gross_sales,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 500000 THEN 'HIGH' ELSE 'LOW' END AS sales_volume_category,
    diff_cnt.diff_count,
    inter_cnt.intersect_count
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ws_close.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_wp_access.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
LEFT JOIN (SELECT COUNT(*) AS diff_count FROM diff_set) diff_cnt ON TRUE
LEFT JOIN (SELECT COUNT(*) AS intersect_count FROM intersect_set) inter_cnt ON TRUE
WHERE d_sales.d_year = 2001
GROUP BY d_sales.d_year, ws.web_name, cc.cc_name, diff_cnt.diff_count, inter_cnt.intersect_count
ORDER BY gross_sales DESC
LIMIT 100
