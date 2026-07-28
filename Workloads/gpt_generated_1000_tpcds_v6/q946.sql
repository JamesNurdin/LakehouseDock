WITH base_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cc.cc_call_center_sk,
        cc.cc_name,
        r.r_reason_desc,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_cs.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM inventory i0
        WHERE i0.inv_date_sk = d_cs.d_date_sk
          AND i0.inv_warehouse_sk = w.w_warehouse_sk
          AND i0.inv_quantity_on_hand = 0
    )
)
SELECT
    bs.c_customer_sk,
    bs.c_first_name,
    bs.c_last_name,
    bs.ca_city,
    SUM(bs.cs_ext_sales_price)                         AS catalog_sales,
    SUM(ss.ss_ext_sales_price)                         AS store_sales,
    SUM(ws.ws_ext_sales_price)                         AS web_sales,
    COUNT(DISTINCT bs.cs_order_number)                AS num_orders,
    ROW_NUMBER() OVER (PARTITION BY bs.c_customer_sk ORDER BY SUM(bs.cs_ext_sales_price) DESC) AS sales_rank
FROM base_sales bs
JOIN store_sales ss
    ON ss.ss_customer_sk = bs.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = bs.c_customer_sk
JOIN date_dim d_ws
    ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
WHERE d_ss.d_year = 2001
  AND d_ws.d_year = 2001
GROUP BY
    bs.c_customer_sk,
    bs.c_first_name,
    bs.c_last_name,
    bs.ca_city
ORDER BY catalog_sales DESC
LIMIT 100
