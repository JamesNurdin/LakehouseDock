WITH joined_data AS (
  SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    i.i_item_id,
    i.i_category,
    i.i_size,
    i.i_container,
    i.i_product_name,
    i.i_item_desc,
    sm.sm_ship_mode_id,
    w.w_warehouse_name,
    w.w_county,
    w.w_gmt_offset,
    c.c_customer_id,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    td.t_hour,
    td.t_meal_time,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    ws.ws_quantity AS ws_quantity,
    ws.ws_ext_sales_price AS ws_ext_sales_price,
    ws.ws_net_profit AS ws_net_profit,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss,
    ws_site.web_name,
    t.word AS desc_word
  FROM catalog_sales cs
  INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
  INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  INNER JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  INNER JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  INNER JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  INNER JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
      AND ws.ws_item_sk = i.i_item_sk
      AND ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
      AND ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  INNER JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
      AND cr.cr_item_sk = i.i_item_sk
      AND cr.cr_order_number = cs.cs_order_number
      AND cr.cr_refunded_customer_sk = c.c_customer_sk
      AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
      AND cr.cr_warehouse_sk = w.w_warehouse_sk
      AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
      AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  INNER JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
      AND sr.sr_item_sk = i.i_item_sk
      AND sr.sr_customer_sk = c.c_customer_sk
      AND sr.sr_cdemo_sk = cd.cd_demo_sk
      AND sr.sr_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
  WHERE
    i.i_size IN ('small', 'medium', 'extra large')
    AND w.w_county IN ('Oglethorpe County', 'Huron County')
    AND cd.cd_education_status = 'College'
    AND hd.hd_buy_potential = 'Medium'
    AND td.t_hour BETWEEN 8 AND 20
    AND ib.ib_upper_bound >= 50000
    AND cs.cs_quantity > 5
    AND w.w_warehouse_sk IN (SELECT w2.w_warehouse_sk FROM warehouse w2 WHERE w2.w_county = 'Oglethorpe County')
    AND ws_site.web_name LIKE '%Online%'
),
item_agg AS (
  SELECT
    i_item_id,
    i_category,
    SUM(COALESCE(cs_ext_sales_price, 0) + COALESCE(ws_ext_sales_price, 0) - COALESCE(cr_return_amount, 0) - COALESCE(sr_return_amt, 0)) AS total_sales,
    SUM(COALESCE(cs_net_profit, 0) + COALESCE(ws_net_profit, 0) - COALESCE(cr_net_loss, 0) - COALESCE(sr_net_loss, 0)) AS total_profit,
    COUNT(DISTINCT desc_word) AS distinct_desc_word_cnt
  FROM joined_data
  GROUP BY i_item_id, i_category
)
SELECT
  i_category,
  SUM(total_sales) AS sum_sales,
  AVG(total_profit) AS avg_profit,
  COUNT(DISTINCT i_item_id) AS distinct_items,
  SUM(distinct_desc_word_cnt) AS total_distinct_words
FROM item_agg
GROUP BY i_category
HAVING SUM(total_sales) > 10000
ORDER BY avg_profit DESC
LIMIT 100
