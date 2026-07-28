WITH aggregated_sales AS (
    SELECT
        d_sold.d_year AS year,
        sm_ws.sm_ship_mode_id AS ship_mode_id,
        ib.ib_upper_bound AS income_upper,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty
    FROM store_sales ss
    JOIN date_dim d_sold
      ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
      ON inv.inv_date_sk = d_sold.d_date_sk
    JOIN web_sales ws
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d_ws_sold
      ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN date_dim d_ws_ship
      ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN time_dim t_ws_sold
      ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN ship_mode sm_ws
      ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN date_dim d_cr_return
      ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return
      ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN ship_mode sm_cr
      ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d_sold.d_year BETWEEN 2000 AND 2002
      AND ca.ca_state = 'CA'
      AND ib.ib_upper_bound >= 50000
      AND sm_ws.sm_code = 'AIR'
      AND cc.cc_gmt_offset >= -5.00
    GROUP BY d_sold.d_year, sm_ws.sm_ship_mode_id, ib.ib_upper_bound
)
SELECT
    year,
    AVG(store_net_profit + web_net_profit - catalog_net_loss) AS avg_total_profit,
    SUM(inventory_qty) AS total_inventory
FROM aggregated_sales
GROUP BY year
HAVING AVG(store_net_profit + web_net_profit - catalog_net_loss) > 10000
ORDER BY year DESC
