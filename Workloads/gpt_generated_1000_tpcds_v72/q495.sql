WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk, inv_date_sk
)
SELECT
    ws.ws_order_number,
    d_sold.d_date AS sold_date,
    i.i_item_id,
    i.i_product_name,
    ws.ws_net_paid,
    ws.ws_net_profit,
    cr.cr_return_amount,
    sr.sr_return_amt,
    inv_agg.total_qty,
    ws_site.web_name,
    cp.cp_department,
    ib.ib_upper_bound,
    ROW_NUMBER() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN inv_agg
    ON i.i_item_sk = inv_agg.inv_item_sk
   AND w.w_warehouse_sk = inv_agg.inv_warehouse_sk
   AND d_sold.d_date_sk = inv_agg.inv_date_sk
-- catalog returns
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN time_dim t_cr
    ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
-- store returns
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr
    ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND ib.ib_upper_bound <= 60000
  AND cp.cp_department = 'Electronics'
ORDER BY profit_rank, ws.ws_net_profit DESC
LIMIT 100
