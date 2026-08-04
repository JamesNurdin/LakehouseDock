WITH intersect_orders AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
    INTERSECT
    SELECT sr.sr_ticket_number AS order_number
    FROM store_returns sr
    WHERE sr.sr_return_amt > 150
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cc.cc_name,
        cp.cp_department,
        r.r_reason_desc,
        r.r_reason_id,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    WHERE cc.cc_rec_end_date = DATE '2000-12-31'
      AND td.t_hour = 14
      AND r.r_reason_id = 'AAAAAAAADBAAAAAA'
      AND cs.cs_order_number IN (SELECT order_number FROM intersect_orders)
)
SELECT
    cc_name,
    cp_department,
    r_reason_desc,
    t_hour,
    COUNT(DISTINCT cs_order_number) AS orders_count,
    SUM(cs_net_paid) AS total_net_paid,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(cs_sold_date_sk) AS earliest_sold_date_sk,
    MAX(cs_sold_date_sk) AS latest_sold_date_sk,
    (SELECT COUNT(*) FROM catalog_sales) AS total_sales_all
FROM joined_data
GROUP BY cc_name, cp_department, r_reason_desc, t_hour
ORDER BY total_net_paid DESC, orders_count DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
