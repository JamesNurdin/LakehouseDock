WITH sales_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
)
SELECT
    s.s_state,
    s.s_city,
    d.d_year,
    cc.cc_name,
    cp.cp_type,
    ib.ib_lower_bound,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(sd.ss_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
    (SELECT AVG(ib_sub.ib_lower_bound)
     FROM income_band ib_sub
     WHERE ib_sub.ib_upper_bound <= 200000) AS avg_income_lower_bound
FROM sales_data sd
JOIN store s
  ON sd.ss_store_sk = s.s_store_sk
JOIN date_dim d
  ON sd.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON sd.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON sd.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON sd.ss_addr_sk = ca.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
 AND inv.inv_date_sk = d.d_date_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    s.s_state = 'TX'                     -- filter 1
    AND s.s_county = 'Mobile County'     -- filter 2
    AND d.d_year = 2002                  -- filter 3
    AND cc.cc_mkt_id IN (1, 2, 3)        -- filter 4
    AND cp.cp_type = 'PROMO'             -- filter 5
    AND inv.inv_quantity_on_hand > 0    -- filter 6
    AND ib.ib_upper_bound <= 200000     -- filter 7
GROUP BY
    ROLLUP (s.s_state, s.s_city, d.d_year, cc.cc_name, cp.cp_type, ib.ib_lower_bound)
ORDER BY
    total_net_paid DESC
LIMIT 100
