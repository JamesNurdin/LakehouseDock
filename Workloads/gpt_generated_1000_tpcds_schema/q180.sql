SELECT
    c.c_customer_id,
    i.i_category,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    MIN(cs.cs_ext_discount_amt) AS min_discount,
    MAX(cs.cs_ext_sales_price) AS max_ext_sales,
    SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_paid ELSE 0 END) AS profit_sales
FROM catalog_sales cs
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN inventory inv
  ON cs.cs_item_sk = inv.inv_item_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
FULL OUTER JOIN store_returns sr
  ON sr.sr_item_sk = i.i_item_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN time_dim td
  ON sr.sr_return_time_sk = td.t_time_sk
JOIN web_page wp
  ON c.c_customer_sk = wp.wp_customer_sk
JOIN web_returns wr
  ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE cs.cs_quantity > 5
  AND cs.cs_ext_sales_price > 200.00
  AND c.c_birth_year BETWEEN 1950 AND 1965
  AND cd.cd_gender = 'M'
  AND hd.hd_vehicle_count >= 2
  AND ib.ib_upper_bound <= 100000
  AND wp.wp_char_count > 4000
GROUP BY c.c_customer_id, i.i_category
ORDER BY total_net_paid DESC
LIMIT 100
