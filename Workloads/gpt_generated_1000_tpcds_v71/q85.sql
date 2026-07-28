WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit,
        cp.cp_catalog_page_sk,
        cp.cp_department,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        i.i_item_sk,
        i.i_brand,
        i.i_current_price,
        c.c_customer_sk,
        c.c_birth_year,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_reason_sk,
        r.r_reason_sk,
        r.r_reason_desc,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        ws.ws_item_sk,
        ws.ws_ext_list_price,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE cp.cp_department = 'Electronics'
      AND w.w_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND c.c_birth_year = 1990
      AND cr.cr_return_quantity > 1
      AND ws.ws_ext_list_price > 5000
) 
SELECT
    w.w_warehouse_name AS warehouse_name,
    cp.cp_department AS department,
    i.i_brand AS brand,
    c.c_birth_year AS birth_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ws.ws_ext_list_price) AS avg_ext_list_price,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
FROM base
JOIN catalog_sales cs        ON cs.cs_order_number = base.cs_order_number
JOIN catalog_page cp         ON cp.cp_catalog_page_sk = base.cp_catalog_page_sk
JOIN warehouse w             ON w.w_warehouse_sk = base.w_warehouse_sk
JOIN item i                  ON i.i_item_sk = base.i_item_sk
JOIN customer c              ON c.c_customer_sk = base.c_customer_sk
JOIN catalog_returns cr      ON cr.cr_order_number = base.cs_order_number
JOIN reason r                ON r.r_reason_sk = base.r_reason_sk
JOIN store_returns sr        ON sr.sr_item_sk = base.i_item_sk
JOIN web_sales ws            ON ws.ws_item_sk = base.i_item_sk
JOIN inventory inv           ON inv.inv_item_sk = base.i_item_sk
GROUP BY
    w.w_warehouse_name,
    cp.cp_department,
    i.i_brand,
    c.c_birth_year
HAVING SUM(cs.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
