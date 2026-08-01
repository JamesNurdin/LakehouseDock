WITH
    sales_pre AS (
        SELECT
            cs.cs_order_number,
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_warehouse_sk,
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_promo_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_net_paid,
            cs.cs_bill_cdemo_sk,
            cs.cs_bill_hdemo_sk,
            cs.cs_bill_addr_sk,
            cs.cs_ship_cdemo_sk,
            cs.cs_ship_hdemo_sk,
            cs.cs_ship_addr_sk
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 0
    ),
    high_value_orders AS (
        SELECT cs_order_number
        FROM sales_pre
        WHERE cs_ext_sales_price > 1000
    ),
    orders_not_returned AS (
        SELECT cs_order_number
        FROM high_value_orders
        EXCEPT
        SELECT cr_order_number AS cs_order_number
        FROM catalog_returns
    ),
    high_returned_orders AS (
        SELECT cs_order_number
        FROM high_value_orders
        INTERSECT
        SELECT cr_order_number AS cs_order_number
        FROM catalog_returns
    ),
    agg_main AS (
        SELECT
            d.d_year,
            i.i_category,
            w.w_state,
            SUM(sp.cs_net_paid) AS total_net_paid,
            SUM(sp.cs_quantity) AS total_quantity,
            COUNT(DISTINCT sp.cs_order_number) AS distinct_orders,
            CASE
                WHEN SUM(sp.cs_quantity) > 1000 THEN 'HIGH_VOLUME'
                ELSE 'LOW_VOLUME'
            END AS volume_flag,
            COUNT(DISTINCT p_latest.p_promo_name) AS distinct_promos
        FROM sales_pre sp
        JOIN orders_not_returned onr
            ON sp.cs_order_number = onr.cs_order_number
        JOIN date_dim d
            ON sp.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t
            ON sp.cs_sold_time_sk = t.t_time_sk
        JOIN item i
            ON sp.cs_item_sk = i.i_item_sk
        JOIN warehouse w
            ON sp.cs_warehouse_sk = w.w_warehouse_sk
        JOIN call_center cc
            ON sp.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON sp.cs_catalog_page_sk = cp.cp_catalog_page_sk
        -- store via its closed date
        JOIN store s
            ON s.s_closed_date_sk = d.d_date_sk
        -- inventory on the same date, item and warehouse
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
               AND inv.inv_warehouse_sk = w.w_warehouse_sk
               AND inv.inv_date_sk = d.d_date_sk
        -- billing address
        JOIN customer_address ca_bill
            ON sp.cs_bill_addr_sk = ca_bill.ca_address_sk
        -- shipping address
        JOIN customer_address ca_ship
            ON sp.cs_ship_addr_sk = ca_ship.ca_address_sk
        -- billing customer demographics
        JOIN customer_demographics cd_bill
            ON sp.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        -- billing household demographics
        JOIN household_demographics hd_bill
            ON sp.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        -- optional returns information
        LEFT JOIN catalog_returns cr
            ON cr.cr_order_number = sp.cs_order_number
               AND cr.cr_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i.i_item_sk
               AND wr.wr_returned_date_sk = d.d_date_sk
        -- latest active promotion for the item (LATERAL)
        CROSS JOIN LATERAL (
            SELECT p.p_promo_name
            FROM promotion p
            WHERE p.p_item_sk = i.i_item_sk
              AND p.p_discount_active = 'Y'
            ORDER BY p.p_start_date_sk DESC
            LIMIT 1
        ) AS p_latest
        WHERE d.d_year BETWEEN 2001 AND 2002
          AND i.i_current_price > 50
          AND w.w_state IN ('CA', 'TX')
          AND cc.cc_division = 2
          AND cp.cp_type = 'Type1'
        GROUP BY ROLLUP (d.d_year, i.i_category, w.w_state)
    )
SELECT
    d_year,
    i_category,
    w_state,
    total_net_paid,
    total_quantity,
    distinct_orders,
    volume_flag,
    distinct_promos,
    (SELECT COUNT(*) FROM high_returned_orders) AS high_returned_order_cnt,
    RANK() OVER (PARTITION BY i_category ORDER BY total_net_paid DESC) AS category_rank
FROM agg_main
ORDER BY d_year NULLS LAST,
         i_category NULLS LAST,
         w_state NULLS LAST,
         total_net_paid DESC
LIMIT 100
