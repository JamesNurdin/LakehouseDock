WITH avg_price_per_item AS (
    SELECT cs_item_sk, avg(cs_ext_sales_price) AS avg_price
    FROM catalog_sales
    GROUP BY cs_item_sk
)
SELECT
    i.i_category AS category,
    d_sales.d_year AS sales_year,
    hd_bill.hd_buy_potential AS buy_potential,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    sum(cs.cs_net_profit) AS total_catalog_profit,
    sum(ws.ws_net_profit) AS total_web_profit,
    sum(cr.cr_net_loss) AS total_catalog_returns_loss,
    sum(wr.wr_net_loss) AS total_web_returns_loss,
    sum(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    avg(ap.avg_price) AS avg_item_price
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sales ON ws.ws_sold_date_sk = d_ws_sales.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
    AND inv.inv_date_sk = d_sales.d_date_sk
JOIN avg_price_per_item ap ON ap.cs_item_sk = cs.cs_item_sk
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr2
    WHERE cr2.cr_item_sk = cs.cs_item_sk
      AND cr2.cr_return_amount > 100
)
GROUP BY
    i.i_category,
    d_sales.d_year,
    hd_bill.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING sum(cs.cs_net_profit) > 10000
ORDER BY total_catalog_profit DESC
LIMIT 100
