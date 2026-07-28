WITH base AS (
    SELECT 
        t.t_sub_shift,
        ca.ca_state,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        ss.ss_net_paid,
        cr.cr_return_amount,
        ws.ws_order_number,
        i.i_current_price,
        inv.inv_quantity_on_hand
    FROM tpcds.time_dim t
    JOIN tpcds.store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
                                 AND cr.cr_item_sk = i.i_item_sk
                                 AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
                               AND ws.ws_item_sk = i.i_item_sk
                               AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND i.i_brand = 'Brand#23'
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND r.r_reason_desc LIKE '%price%'
      AND wsite.web_country = 'United States'
      AND NOT EXISTS (
          SELECT 1 FROM tpcds.inventory inv2
          WHERE inv2.inv_item_sk = i.i_item_sk
            AND inv2.inv_quantity_on_hand > 0
      )
)
SELECT 
    t_sub_shift,
    ca_state,
    profit_category,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    AVG(i_current_price) AS avg_price,
    SUM(inv_quantity_on_hand) AS total_qty_on_hand
FROM base
GROUP BY t_sub_shift, ca_state, profit_category
HAVING SUM(ss_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
