WITH
    catalog_join AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_ext_sales_price,
            cs.cs_ext_discount_amt,
            cs.cs_order_number,
            i.i_product_name,
            i.i_size,
            sm.sm_type,
            d.d_date,
            t.t_meal_time,
            cc.cc_call_center_id,
            ca.ca_state,
            hd.hd_buy_potential
        FROM catalog_sales cs
        JOIN date_dim d                ON cs.cs_sold_date_sk   = d.d_date_sk
        JOIN time_dim t                ON cs.cs_sold_time_sk   = t.t_time_sk
        JOIN item i                    ON cs.cs_item_sk        = i.i_item_sk
        JOIN ship_mode sm              ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
        JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca       ON cs.cs_bill_addr_sk   = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk  = hd.hd_demo_sk
        WHERE d.d_date = DATE '2001-01-01'
          AND i.i_size = 'large'
          AND sm.sm_type = 'AIR'
          AND t.t_meal_time = 'dinner'
    ),
    web_join AS (
        SELECT
            ws.ws_item_sk        AS cs_item_sk,
            ws.ws_ext_sales_price AS cs_ext_sales_price,
            ws.ws_ext_discount_amt AS cs_ext_discount_amt,
            ws.ws_order_number   AS cs_order_number,
            i.i_product_name,
            i.i_size,
            sm.sm_type,
            d.d_date,
            t.t_meal_time,
            ca.ca_state,
            hd.hd_buy_potential
        FROM web_sales ws
        JOIN date_dim d                ON ws.ws_sold_date_sk   = d.d_date_sk
        JOIN time_dim t                ON ws.ws_sold_time_sk   = t.t_time_sk
        JOIN item i                    ON ws.ws_item_sk        = i.i_item_sk
        JOIN ship_mode sm              ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
        JOIN customer_address ca       ON ws.ws_bill_addr_sk   = ca.ca_address_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk  = hd.hd_demo_sk
        WHERE d.d_date = DATE '2001-01-01'
          AND i.i_size = 'large'
          AND sm.sm_type = 'AIR'
          AND t.t_meal_time = 'dinner'
    ),
    union_sales AS (
        SELECT cs_item_sk, cs_ext_sales_price, cs_ext_discount_amt, cs_order_number
        FROM catalog_join
        UNION
        SELECT cs_item_sk, cs_ext_sales_price, cs_ext_discount_amt, cs_order_number
        FROM web_join
    ),
    diff_items AS (
        SELECT COUNT(*) AS cnt
        FROM (
            SELECT cs.cs_item_sk FROM catalog_sales cs
            EXCEPT
            SELECT sr.sr_item_sk FROM store_returns sr
        ) sub
    ),
    full_outer AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_return_amt,
            d.d_date           AS return_date,
            t.t_meal_time      AS return_meal_time,
            r.r_reason_desc
        FROM store_returns sr
        FULL OUTER JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        LEFT JOIN time_dim t      ON sr.sr_return_time_sk   = t.t_time_sk
        LEFT JOIN reason r        ON sr.sr_reason_sk        = r.r_reason_sk
        WHERE d.d_date = DATE '2001-01-01' OR d.d_date IS NULL
    ),
    inventory_usage AS (
        SELECT i.i_item_sk, inv.inv_quantity_on_hand, d.d_date
        FROM inventory inv
        JOIN item i          ON inv.inv_item_sk = i.i_item_sk
        JOIN date_dim d      ON inv.inv_date_sk = d.d_date_sk
        WHERE d.d_date = DATE '2001-01-01'
    )
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_size,
    SUM(us.cs_ext_sales_price)                                     AS total_sales,
    AVG(us.cs_ext_discount_amt)                                    AS avg_discount,
    COUNT(DISTINCT us.cs_order_number)                             AS distinct_orders,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     WHERE sr2.sr_item_sk = i.i_item_sk)                         AS total_store_return_amt,
    (SELECT COUNT(DISTINCT sr3.sr_return_quantity)
     FROM store_returns sr3
     WHERE sr3.sr_item_sk = i.i_item_sk)                         AS distinct_return_qty_cnt,
    diff_items.cnt                                                AS items_not_returned_cnt,
    COUNT(DISTINCT fo.sr_item_sk)                                 AS full_outer_return_items,
    COALESCE(inv.inv_quantity_on_hand, 0)                         AS quantity_on_hand_on_2001_01_01
FROM union_sales us
JOIN item i               ON us.cs_item_sk = i.i_item_sk
LEFT JOIN full_outer fo   ON fo.sr_item_sk = i.i_item_sk
LEFT JOIN inventory_usage inv ON inv.i_item_sk = i.i_item_sk
CROSS JOIN diff_items
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    i.i_size,
    diff_items.cnt,
    inv.inv_quantity_on_hand
ORDER BY total_sales DESC
LIMIT 100
