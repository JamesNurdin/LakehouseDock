WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_ext_wholesale_cost,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        ca_bill.ca_state,
        ca_bill.ca_country,
        w.w_state,
        w.w_zip,
        p.p_discount_active,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_dow,
        t.t_hour,
        inv.inv_quantity_on_hand,
        s.s_state,
        wp.wp_type,
        (
            SELECT MAX(p2.p_cost)
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
        ) AS max_promo_cost
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    WHERE cs.cs_net_paid_inc_ship_tax > 5000
      AND cs.cs_call_center_sk IN (1, 2, 13)
      AND ca_bill.ca_state = 'CA'
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND d_sold.d_dow = 5
      AND inv.inv_quantity_on_hand > 0
      AND s.s_state = 'TX'
      AND wp.wp_type = 'home'
      AND EXISTS (
          SELECT 1
          FROM promotion p3
          WHERE p3.p_promo_sk = cs.cs_promo_sk
            AND p3.p_discount_active = 'Y'
            AND p3.p_start_date_sk <= cs.cs_sold_date_sk
            AND p3.p_end_date_sk >= cs.cs_sold_date_sk
      )
)
SELECT
    d_year,
    d_month_seq,
    w_state,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales,
    AVG(cs_ext_wholesale_cost) AS avg_wholesale_cost,
    SUM(inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity,
    MAX(max_promo_cost) AS max_promo_cost
FROM base
WHERE d_year = 1998
GROUP BY ROLLUP (d_year, d_month_seq, w_state)

UNION ALL

SELECT
    d_year,
    d_month_seq,
    w_state,
    SUM(cs_net_paid_inc_ship_tax) AS total_sales,
    AVG(cs_ext_wholesale_cost) AS avg_wholesale_cost,
    SUM(inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    MIN(cs_quantity) AS min_quantity,
    MAX(cs_quantity) AS max_quantity,
    MAX(max_promo_cost) AS max_promo_cost
FROM base
WHERE d_year = 1999
GROUP BY ROLLUP (d_year, d_month_seq, w_state)

LIMIT 100
