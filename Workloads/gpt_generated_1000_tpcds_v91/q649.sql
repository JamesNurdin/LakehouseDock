WITH high_value_orders AS (
    SELECT cs_order_number
    FROM tpcds.catalog_sales
    WHERE cs_ext_sales_price > 2000
),
returned_orders AS (
    SELECT cr_order_number
    FROM tpcds.catalog_returns
    WHERE cr_return_quantity > 0
),
orders_without_returns AS (
    SELECT cs_order_number
    FROM high_value_orders
    EXCEPT
    SELECT cr_order_number
    FROM returned_orders
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_item_id,
        i.i_current_price,
        w.w_city,
        w.w_gmt_offset,
        td.t_hour AS sale_hour,
        cp.cp_department,
        sm.sm_type,
        p.p_discount_active,
        cd.cd_gender,
        inv.inv_quantity_on_hand,
        ss.ss_ticket_number,
        RANK() OVER (PARTITION BY w.w_city ORDER BY cs.cs_ext_sales_price DESC) AS city_sales_rank
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN tpcds.time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    INNER JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    INNER JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
    WHERE i.i_current_price > 100
      AND td.t_hour BETWEEN 8 AND 12
      AND w.w_gmt_offset BETWEEN -5 AND 0
      AND EXISTS (
          SELECT 1
          FROM tpcds.call_center cc
          WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
            AND cc.cc_country = 'United States'
      )
      AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
)
SELECT
    jd.cs_order_number,
    jd.cs_ext_sales_price,
    jd.cs_net_profit,
    jd.i_item_id,
    jd.i_current_price,
    jd.w_city,
    jd.sale_hour,
    jd.city_sales_rank
FROM joined_data jd
ORDER BY jd.city_sales_rank, jd.cs_ext_sales_price DESC
LIMIT 100
