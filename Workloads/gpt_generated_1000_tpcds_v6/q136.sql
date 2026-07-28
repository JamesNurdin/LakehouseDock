WITH sales_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_sk,
        i.i_product_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        MAX(cs.cs_sold_date_sk) AS latest_sold_date_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        c.c_birth_year BETWEEN 1950 AND 1960
        AND i.i_current_price > 50
        AND cc.cc_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND p.p_channel_details LIKE '%rare%'
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_sk,
        i.i_product_name
),
customer_with_web_returns AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_returns wr
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE EXISTS (
        SELECT 1
        FROM time_dim td2
        WHERE td2.t_time_sk = wr.wr_returned_time_sk
          AND td2.t_hour BETWEEN 8 AND 12
    )
)
SELECT
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    COUNT(DISTINCT ss.i_item_sk) AS distinct_items,
    SUM(ss.total_net_paid) AS agg_net_paid,
    AVG(ss.total_return_amount) AS avg_return_amount,
    SUM(ss.total_quantity) AS total_quantity,
    SUM(ss.total_net_paid) / NULLIF(COUNT(DISTINCT ss.i_item_sk), 0) AS avg_net_per_item
FROM sales_summary ss
JOIN customer_with_web_returns cwr ON ss.c_customer_sk = cwr.c_customer_sk
GROUP BY
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name
HAVING SUM(ss.total_net_paid) > 10000
ORDER BY agg_net_paid DESC
LIMIT 100
