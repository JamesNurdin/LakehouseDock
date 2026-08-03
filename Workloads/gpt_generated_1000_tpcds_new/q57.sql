WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_date,
        i.i_product_name,
        i.i_category,
        ca.ca_state,
        ca.ca_city,
        sm.sm_type,
        p.p_promo_name,
        w.w_warehouse_name,
        wp.wp_image_count,
        s.s_store_name,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        t.t_shift
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
      ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer_address ca
      ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s
      ON s.s_closed_date_sk = d.d_date_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
         AND inv.inv_warehouse_sk = w.w_warehouse_sk
         AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ca.ca_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND t.t_shift = 'first'
)
SELECT
    sd.ws_order_number,
    sd.ws_net_paid,
    sd.ws_net_profit,
    sd.d_date,
    sd.i_product_name,
    sd.s_store_name,
    sd.w_warehouse_name,
    sd.sm_type,
    sd.p_promo_name,
    sd.ca_city,
    sd.hd_vehicle_count,
    sd.ib_upper_bound,
    sd.wp_image_count,
    RANK() OVER (PARTITION BY sd.s_store_name ORDER BY sd.ws_net_profit DESC) AS profit_rank,
    (SELECT SUM(wr2.wr_return_quantity)
       FROM web_returns wr2
      WHERE wr2.wr_order_number = sd.ws_order_number) AS total_return_qty
FROM sales_data sd
ORDER BY profit_rank, sd.ws_net_profit DESC
LIMIT 100
