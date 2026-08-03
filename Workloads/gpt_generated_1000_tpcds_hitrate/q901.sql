WITH
    /* 1. Base catalog sales enriched with many related dimensions */
    cs_base AS (
        SELECT
            cs.cs_order_number,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cs.cs_sold_date_sk,
            cs.cs_ship_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_bill_customer_sk,
            cs.cs_bill_addr_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_ship_mode_sk,
            d_sold.d_date            AS sold_date,
            d_ship.d_date            AS ship_date,
            t_sold.t_hour            AS sold_hour,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            c.c_customer_id,
            ca.ca_city               AS bill_city,
            hd.hd_income_band_sk,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type
        FROM catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
        JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
        JOIN item i          ON cs.cs_item_sk = i.i_item_sk
        JOIN customer c      ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN call_center cc  ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    ),
    /* 2. Catalog returns + reason */
    cr_base AS (
        SELECT
            cr.cr_order_number,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            r.r_reason_desc
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    ),
    /* 3. Web sales enriched */
    ws_base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_ext_discount_amt,
            d_ws.d_date          AS ws_sold_date,
            i_ws.i_item_id       AS ws_item_id,
            c_ws.c_customer_id   AS ws_customer_id,
            sm_ws.sm_type        AS ws_ship_type,
            web.web_name         AS ws_site_name
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN item i_ws   ON ws.ws_item_sk = i_ws.i_item_sk
        JOIN customer c_ws ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    ),
    /* 4. Inventory snapshot for the same items */
    inv_base AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_quantity_on_hand,
            d_inv.d_date          AS inv_date
        FROM inventory inv
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN item i_inv     ON inv.inv_item_sk = i_inv.i_item_sk
    ),
    /* 5. Orders that appear in catalog_sales but NOT in web_sales */
    exclusive_orders AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT ws_order_number FROM web_sales
    ),
    /* 6. Combine everything */
    combined AS (
        SELECT
            cs.cs_order_number,
            cs.sold_date,
            cs.c_customer_id,
            cs.i_item_id,
            cs.i_brand,
            cs.cs_quantity,
            cs.cs_net_paid,
            cs.cs_net_profit,
            cr.r_reason_desc,
            ws.ws_quantity               AS ws_quantity,
            ws.ws_net_paid               AS ws_net_paid,
            ws.ws_ext_discount_amt       AS ws_discount,
            inv.inv_quantity_on_hand     AS inventory_on_hand,
            st.s_store_name               AS store_name,
            /* scalar sub‑query: average web‑sale discount for the same item */
            (SELECT avg(ws2.ws_ext_discount_amt)
             FROM web_sales ws2
             WHERE ws2.ws_item_sk = cs.cs_item_sk) AS avg_ws_discount,
            /* window functions */
            ROW_NUMBER() OVER (PARTITION BY cs.c_customer_id ORDER BY cs.cs_net_paid DESC) AS rn_by_customer,
            DENSE_RANK()  OVER (ORDER BY cs.cs_net_profit DESC)                     AS dr_by_profit
        FROM cs_base cs
        LEFT JOIN cr_base cr   ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN ws_base ws   ON cs.cs_order_number = ws.ws_order_number
        LEFT JOIN inv_base inv ON cs.cs_item_sk = inv.inv_item_sk
        LEFT JOIN store st      ON st.s_closed_date_sk = cs.cs_ship_date_sk
        WHERE cs.cs_quantity > 5
          AND cs.cs_net_paid > 1000
          AND cs.sold_date >= DATE '2001-01-01'
          AND EXISTS (SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = cs.cs_order_number AND cr2.cr_return_quantity > 0)
          AND cs.cs_order_number IN (SELECT cs_order_number FROM exclusive_orders)
    )
SELECT
    cn.cs_order_number,
    cn.sold_date,
    cn.c_customer_id,
    cn.i_item_id,
    cn.i_brand,
    cn.cs_quantity,
    cn.cs_net_paid,
    cn.r_reason_desc,
    cn.ws_net_paid,
    cn.inventory_on_hand,
    cn.store_name,
    cn.avg_ws_discount,
    cn.rn_by_customer,
    cn.dr_by_profit
FROM combined cn
GROUP BY
    cn.cs_order_number,
    cn.sold_date,
    cn.c_customer_id,
    cn.i_item_id,
    cn.i_brand,
    cn.cs_quantity,
    cn.cs_net_paid,
    cn.r_reason_desc,
    cn.ws_net_paid,
    cn.inventory_on_hand,
    cn.store_name,
    cn.avg_ws_discount,
    cn.rn_by_customer,
    cn.dr_by_profit
HAVING sum(cn.cs_net_paid) > 5000
ORDER BY cn.cs_net_paid DESC
LIMIT 100
