WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_category,
        w.w_state,
        sm.sm_type,
        p.p_promo_name,
        cp.cp_department,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        inv.inv_quantity_on_hand,
        ss.ss_quantity AS store_quantity,
        ss.ss_net_paid,
        wp.wp_image_count,
        ca.ca_city,
        ca.ca_state,
        t.t_meal_time,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
           AND p.p_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN reason rp
        ON cr.cr_reason_sk = rp.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
           AND inv.inv_date_sk = d.d_date_sk
           AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
           AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND w.w_state = 'CA'
      AND t.t_meal_time = 'lunch'
      AND cs.cs_quantity > 5
      AND cr.cr_return_amount > 10
),
sales_agg AS (
    SELECT
        d_year,
        i_category,
        w_state,
        sm_type,
        p_promo_name,
        cp_department,
        SUM(cs_net_paid) AS total_cs_net_paid,
        SUM(cs_net_profit) AS total_cs_net_profit,
        SUM(cr_return_amount) AS total_cr_return_amount,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(*) AS transaction_cnt,
        AVG(ss_net_paid) AS avg_store_net_paid,
        MAX(cs_net_paid) AS max_cs_net_paid
    FROM joined_data
    GROUP BY ROLLUP (d_year, i_category, w_state, sm_type, p_promo_name, cp_department)
)
SELECT *
FROM (
    SELECT
        d_year,
        i_category,
        w_state,
        total_cs_net_paid,
        total_cs_net_profit,
        total_inventory,
        avg_store_net_paid,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = agg.d_year) AS avg_year_cs_net_paid
    FROM sales_agg agg
    WHERE total_cs_net_paid > 50000
) 
UNION ALL
SELECT *
FROM (
    SELECT
        d_year,
        i_category,
        w_state,
        total_cs_net_paid,
        total_cs_net_profit,
        total_inventory,
        avg_store_net_paid,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
         WHERE d2.d_year = agg.d_year) AS avg_year_cs_net_paid
    FROM sales_agg agg
    WHERE total_inventory > 1000
) 
ORDER BY d_year DESC, i_category
LIMIT 100
