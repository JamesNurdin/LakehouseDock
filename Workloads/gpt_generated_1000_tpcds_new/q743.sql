WITH
    sampled_returns AS (
        SELECT cr_order_number, cr_return_amount
        FROM catalog_returns TABLESAMPLE BERNOULLI (5)
    ),
    order_intersect AS (
        SELECT cs_order_number AS order_number
        FROM catalog_sales
        WHERE cs_sold_date_sk BETWEEN 2451910 AND 2452000
        INTERSECT
        SELECT ws_order_number
        FROM web_sales
        WHERE ws_sold_date_sk BETWEEN 2451910 AND 2452000
    ),
    order_except AS (
        SELECT cc_call_center_id
        FROM call_center
        EXCEPT
        SELECT cc_call_center_id
        FROM call_center
        WHERE cc_state = 'CA'
    ),
    scalar_avg_qty AS (
        SELECT AVG(ws_quantity) AS avg_qty
        FROM web_sales
    )
SELECT
    cc.cc_name,
    w.w_state,
    r.r_reason_desc,
    td.t_hour,
    COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
    SUM(cs.cs_net_paid) AS total_sales,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sales_price) AS min_price,
    MAX(cs.cs_sales_price) AS max_price,
    SUM(sr.cr_return_amount) AS total_return_amount
FROM
    catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN sampled_returns sr ON sr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
WHERE
    cc.cc_rec_start_date > DATE '2000-01-01'
    AND wp.wp_rec_end_date < DATE '2002-01-01'
    AND r.r_reason_desc LIKE '%missing%'
    AND w.w_city = 'Seattle'
    AND cs.cs_quantity > (SELECT avg_qty FROM scalar_avg_qty)
    AND cs.cs_order_number IN (SELECT order_number FROM order_intersect)
    AND cc.cc_call_center_id IN (SELECT cc_call_center_id FROM order_except)
GROUP BY
    cc.cc_name,
    w.w_state,
    r.r_reason_desc,
    td.t_hour
LIMIT 100
