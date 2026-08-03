WITH first AS (
    SELECT
        cc.cc_name,
        ca_store.ca_state,
        i.i_brand,
        r.r_reason_desc,
        p.p_promo_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
        MAX(ss.ss_ext_sales_price) AS max_ext_sales_price,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS max_brand_price
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_sales ss ON td.t_time_sk = ss.ss_sold_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND ca_refund.ca_gmt_offset = -6.00
      AND i.i_wholesale_cost > 20.00
      AND cr.cr_return_amount > 500.00
      AND p.p_discount_active = 'Y'
    GROUP BY cc.cc_name, ca_store.ca_state, i.i_brand, r.r_reason_desc, p.p_promo_name
),
second AS (
    SELECT
        cc.cc_name,
        ca_store.ca_state,
        i.i_brand,
        r.r_reason_desc,
        p.p_promo_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(ss.ss_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
        MAX(ss.ss_ext_sales_price) AS max_ext_sales_price,
        (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_brand = i.i_brand) AS max_brand_price
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN store_sales ss ON td.t_time_sk = ss.ss_sold_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
    WHERE cc.cc_state = 'TX'
      AND ca_refund.ca_gmt_offset = -5.00
      AND i.i_wholesale_cost > 30.00
      AND cr.cr_return_amount > 1000.00
      AND p.p_discount_active = 'Y'
    GROUP BY cc.cc_name, ca_store.ca_state, i.i_brand, r.r_reason_desc, p.p_promo_name
)
SELECT *
FROM (
    SELECT * FROM first
    UNION
    SELECT * FROM second
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
