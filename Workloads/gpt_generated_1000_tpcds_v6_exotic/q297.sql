WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (10, 12, 14, 18, 20)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d_cs.d_year,
    i.i_brand,
    sm_cs.sm_carrier,
    CASE
        WHEN ib.ib_upper_bound > 50000 THEN 'High'
        ELSE 'Low'
    END AS income_category,
    SUM(cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss,
    SUM(inv_agg.total_qty_on_hand) AS total_qty_on_hand
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
WHERE d_cs.d_year = 2001
  AND i.i_brand = 'Brand#45'
  AND sm_cs.sm_carrier = 'DIAMOND'
  AND ib.ib_lower_bound >= 20000
  AND t_cs.t_hour BETWEEN 9 AND 17
GROUP BY
    d_cs.d_year,
    i.i_brand,
    sm_cs.sm_carrier,
    CASE WHEN ib.ib_upper_bound > 50000 THEN 'High' ELSE 'Low' END
ORDER BY total_net_loss DESC
LIMIT 100
