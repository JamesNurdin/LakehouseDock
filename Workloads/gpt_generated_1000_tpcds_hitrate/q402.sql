WITH base AS (
    SELECT
        d.d_year,
        cc.cc_name,
        w.w_warehouse_name,
        cp.cp_department,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        i.inv_quantity_on_hand,
        c.c_birth_country,
        cc.cc_state,
        w.w_state,
        -- lateral aggregate of inventory for the same warehouse and date
        inv_agg.total_inv,
        EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
              AND ws2.ws_sold_date_sk = d.d_date_sk
        ) AS has_web_sales
    FROM catalog_sales cs
    RIGHT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i2.inv_quantity_on_hand) AS total_inv
        FROM inventory i2
        WHERE i2.inv_date_sk = d.d_date_sk
          AND i2.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_agg
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'United States'
      AND cc.cc_state = 'CA'
      AND cp.cp_department = 'DEPARTMENT'
      AND w.w_state = 'TX'
      AND (i.inv_quantity_on_hand > 500 OR i.inv_quantity_on_hand IS NULL)
)
SELECT
    d_year,
    cc_name,
    w_warehouse_name,
    cp_department,
    SUM(cs_net_paid)                     AS total_net_paid,
    COUNT(DISTINCT cs_order_number)      AS order_cnt,
    AVG(cs_ext_discount_amt)             AS avg_discount,
    MAX(cs_quantity)                     AS max_quantity,
    MAX(total_inv)                       AS warehouse_total_inventory,
    SUM(CASE WHEN has_web_sales THEN 1 ELSE 0 END) AS web_sales_flag_count
FROM base
GROUP BY d_year, cc_name, w_warehouse_name, cp_department
UNION DISTINCT
SELECT
    d_year,
    cc_name,
    w_warehouse_name,
    cp_department,
    SUM(cs_net_paid)                     AS total_net_paid,
    COUNT(DISTINCT cs_order_number)      AS order_cnt,
    AVG(cs_ext_discount_amt)             AS avg_discount,
    MAX(cs_quantity)                     AS max_quantity,
    MAX(total_inv)                       AS warehouse_total_inventory,
    SUM(CASE WHEN has_web_sales THEN 1 ELSE 0 END) AS web_sales_flag_count
FROM (
    SELECT
        d.d_year,
        cc.cc_name,
        w.w_warehouse_name,
        cp.cp_department,
        cs.cs_net_paid,
        cs.cs_order_number,
        cs.cs_ext_discount_amt,
        cs.cs_quantity,
        i.inv_quantity_on_hand,
        c.c_birth_country,
        cc.cc_state,
        w.w_state,
        inv_agg.total_inv,
        EXISTS (
            SELECT 1
            FROM web_sales ws2
            WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
              AND ws2.ws_sold_date_sk = d.d_date_sk
        ) AS has_web_sales
    FROM catalog_sales cs
    RIGHT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN LATERAL (
        SELECT SUM(i2.inv_quantity_on_hand) AS total_inv
        FROM inventory i2
        WHERE i2.inv_date_sk = d.d_date_sk
          AND i2.inv_warehouse_sk = w.w_warehouse_sk
    ) AS inv_agg
    WHERE d.d_year = 2002
      AND c.c_birth_country = 'Canada'
      AND cc.cc_state = 'NY'
      AND cp.cp_department = 'DEPARTMENT'
      AND w.w_state = 'FL'
      AND (i.inv_quantity_on_hand > 400 OR i.inv_quantity_on_hand IS NULL)
) sub
GROUP BY d_year, cc_name, w_warehouse_name, cp_department
ORDER BY total_net_paid DESC
LIMIT 100
