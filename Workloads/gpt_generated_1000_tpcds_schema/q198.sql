WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    GROUP BY inv_item_sk, inv_warehouse_sk
)

SELECT
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    i.i_manufact_id,
    SUM(ss.ss_net_paid) AS total_sales_amount,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty,
    AVG(ib.ib_upper_bound) AS avg_income_upper_bound
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk
JOIN warehouse w ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
WHERE d.d_year = 2001
  AND ib.ib_upper_bound >= 90000
  AND i.i_manufact_id IN (260, 294)
  AND w.w_state = 'CA'
  AND wp.wp_image_count > 2
GROUP BY d.d_year, d.d_month_seq, i.i_item_id, i.i_manufact_id, ib.ib_upper_bound

UNION DISTINCT

SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_item_id,
    i.i_manufact_id,
    SUM(cs.cs_net_paid) AS total_sales_amount,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty,
    AVG(ib.ib_upper_bound) AS avg_income_upper_bound
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer cb ON cs.cs_bill_customer_sk = cb.c_customer_sk
JOIN customer cs_ship ON cs.cs_ship_customer_sk = cs_ship.c_customer_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg ia ON ia.inv_item_sk = i.i_item_sk
JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = i.i_item_sk
WHERE d_sold.d_year = 2001
  AND ib.ib_upper_bound >= 90000
  AND i.i_manufact_id IN (260, 294)
  AND w.w_state = 'CA'
  AND wp.wp_image_count > 2
GROUP BY d_sold.d_year, d_sold.d_month_seq, i.i_item_id, i.i_manufact_id, ib.ib_upper_bound
ORDER BY total_sales_amount DESC
LIMIT 100
