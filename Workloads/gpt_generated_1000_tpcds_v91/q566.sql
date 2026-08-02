WITH key_exceptions AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001 AND cs.cs_quantity > 5
    EXCEPT
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001 AND ws.ws_quantity > 5
)
SELECT
    d_sold.d_year,
    ca_bill.ca_state,
    sm.sm_type,
    hd.hd_buy_potential,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS cnt_orders,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    MIN(inventory.inv_quantity_on_hand) AS min_inventory_qty,
    MAX(inventory.inv_quantity_on_hand) AS max_inventory_qty,
    u.location_part AS location_part
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_cr_returned ON cr.cr_returned_date_sk = d_cr_returned.d_date_sk
JOIN time_dim t_cr_returned ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
JOIN inventory inventory ON inventory.inv_date_sk = d_sold.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk
JOIN time_dim t_sr_returned ON sr.sr_return_time_sk = t_sr_returned.t_time_sk
JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
JOIN web_sales ws ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_ws_open ON wsite.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close ON wsite.web_close_date_sk = d_ws_close.d_date_sk
CROSS JOIN UNNEST(ARRAY[ca_bill.ca_city, ca_bill.ca_state, ca_bill.ca_country]) AS u(location_part)
WHERE
    d_sold.d_year = 2001
    AND cs.cs_quantity > 10
    AND cr.cr_return_tax > 20.00
    AND inventory.inv_quantity_on_hand < 50
    AND ca_bill.ca_state = 'CA'
    AND wsite.web_tax_percentage > 5.0
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
          AND wr.wr_return_quantity > 0
    )
    AND cs.cs_net_paid > (SELECT MAX(ib_upper_bound) FROM income_band WHERE ib_income_band_sk = 12)
    AND cs.cs_order_number IN (SELECT order_number FROM key_exceptions)
GROUP BY
    d_sold.d_year,
    ca_bill.ca_state,
    sm.sm_type,
    hd.hd_buy_potential,
    u.location_part
ORDER BY total_net_paid DESC
LIMIT 100
