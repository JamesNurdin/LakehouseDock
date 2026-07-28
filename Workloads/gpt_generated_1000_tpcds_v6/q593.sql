SELECT
    d_sold.d_year,
    i.i_category,
    i.i_brand,
    cc.cc_state,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM catalog_sales cs
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca
  ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
  ON i.i_item_sk = inv.inv_item_sk
  AND w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN web_returns wr
  ON i.i_item_sk = wr.wr_item_sk
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
  AND ss.ss_sold_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_brand = 'Brand#21'
  AND p.p_channel_email = 'Y'
  AND cc.cc_state = 'CA'
GROUP BY d_sold.d_year, i.i_category, i.i_brand, cc.cc_state
ORDER BY total_catalog_sales DESC
LIMIT 100
