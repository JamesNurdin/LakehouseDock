WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
),
sales_base AS (
    SELECT
        w.w_state,
        cp.cp_department,
        p.p_promo_id,
        SUM(cs.cs_net_paid) AS total_catalog_net_paid,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(cs.cs_quantity) AS total_catalog_quantity,
        SUM(ws.ws_quantity) AS total_web_quantity,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(wr.wr_return_amt) AS total_web_return_amount,
        AVG(cs.cs_net_profit) AS avg_catalog_net_profit,
        MAX(t.t_time_sk) AS max_time_sk,
        MIN(t.t_time_sk) AS min_time_sk,
        SUM(DISTINCT inv_agg.total_on_hand) AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca_c
      ON cs.cs_bill_addr_sk = ca_c.ca_address_sk
    JOIN household_demographics hd_c
      ON cs.cs_bill_hdemo_sk = hd_c.hd_demo_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cs
      ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = cs.cs_item_sk
      AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_sold_time_sk = t.t_time_sk
      AND ws.ws_warehouse_sk = w.w_warehouse_sk
      AND ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN household_demographics hd_ws
      ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN customer_address ca_ws
      ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
      AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN inventory_agg inv_agg
      ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
    JOIN income_band ib
      ON hd_c.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        t.t_hour = 10
        AND w.w_state = 'CA'
        AND cp.cp_department = 'Sports'
        AND p.p_discount_active = 'Y'
        AND r_cr.r_reason_desc LIKE '%Dam%'
        AND ca_c.ca_state = 'TX'
        AND cs.cs_quantity > (SELECT AVG(cr_return_quantity) FROM catalog_returns)
        AND w.w_warehouse_sq_ft > (SELECT MAX(ib_upper_bound) FROM income_band)
        AND hd_c.hd_vehicle_count >= 2
    GROUP BY
        ROLLUP (w.w_state, cp.cp_department, p.p_promo_id)
)
SELECT
    w_state,
    cp_department,
    p_promo_id,
    total_catalog_net_paid,
    total_web_net_paid,
    total_catalog_quantity,
    total_web_quantity,
    total_catalog_return_amount,
    total_web_return_amount,
    avg_catalog_net_profit,
    max_time_sk,
    min_time_sk,
    total_inventory_on_hand,
    SUM(total_catalog_net_paid) OVER (PARTITION BY w_state ORDER BY cp_department ROWS UNBOUNDED PRECEDING) AS running_state_net_paid
FROM sales_base
ORDER BY
    w_state,
    cp_department,
    p_promo_id
LIMIT 100
