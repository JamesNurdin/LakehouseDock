WITH intersect_items AS (
        SELECT cs_item_sk FROM catalog_sales WHERE cs_quantity > 5
        INTERSECT
        SELECT cs_item_sk FROM catalog_sales WHERE cs_ext_discount_amt > 0
    ),
    customer_avg AS (
        SELECT cs_bill_customer_sk AS cust_sk, AVG(cs_net_paid) AS avg_paid
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    )
SELECT
    cs.cs_order_number,
    c.c_customer_id,
    ca.ca_city,
    cp.cp_description,
    ws.ws_order_number AS web_order_number,
    w.w_warehouse_name,
    sm.sm_type,
    p.p_promo_name,
    t.t_hour,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_net_paid DESC) AS rn_customer,
    CASE WHEN cs.cs_net_paid > ca_avg.avg_paid THEN 'Above Avg' ELSE 'Below Avg' END AS payment_category,
    l.dummy_char
FROM
    catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    FULL OUTER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN web_sales ws ON t.t_time_sk = ws.ws_sold_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    CROSS JOIN LATERAL (
        SELECT val AS dummy_char
        FROM UNNEST(ARRAY['A','B','C']) AS u(val)
        WHERE val = SUBSTR(c.c_first_name, 1, 1)
    ) l
    LEFT JOIN customer_avg ca_avg ON c.c_customer_sk = ca_avg.cust_sk
WHERE
    cs.cs_ship_date_sk BETWEEN 2450800 AND 2450900
    AND cp.cp_department = 'Electronics'
    AND w.w_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND p.p_channel_catalog = 'N'
    AND cs.cs_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse WHERE w_city = 'San Francisco')
    AND cs.cs_item_sk IN (SELECT cs_item_sk FROM intersect_items)
ORDER BY
    cs.cs_net_paid DESC
LIMIT 100
