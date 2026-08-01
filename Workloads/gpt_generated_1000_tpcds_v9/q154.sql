WITH cat_sales AS (
  SELECT 
    i.i_item_sk,
    i.i_category,
    i.i_color,
    d.d_year,
    cd.cd_gender,
    sm.sm_code,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE 
      WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High'
      ELSE 'Low'
    END AS sales_level
  FROM catalog_sales cs
  RIGHT OUTER JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE 
    d.d_year = 2001
    AND cd.cd_credit_rating = 'High Risk'
    AND cd.cd_purchase_estimate >= 5000
    AND sm.sm_code = 'AIR'
    AND p.p_channel_radio = 'N'
    AND i.i_color = 'Red'
  GROUP BY i.i_item_sk, i.i_category, i.i_color, d.d_year, cd.cd_gender, sm.sm_code
),
web_sales AS (
  SELECT 
    i.i_item_sk,
    i.i_category,
    i.i_color,
    d.d_year,
    cd.cd_gender,
    sm.sm_code,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    CASE 
      WHEN SUM(ws.ws_ext_sales_price) > 100000 THEN 'High'
      ELSE 'Low'
    END AS sales_level
  FROM web_sales ws
  RIGHT OUTER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE 
    d.d_year = 2001
    AND cd.cd_credit_rating = 'High Risk'
    AND cd.cd_purchase_estimate >= 5000
    AND sm.sm_code = 'AIR'
    AND p.p_channel_radio = 'N'
    AND i.i_color = 'Red'
  GROUP BY i.i_item_sk, i.i_category, i.i_color, d.d_year, cd.cd_gender, sm.sm_code
),
combined AS (
  SELECT * FROM cat_sales
  UNION ALL
  SELECT * FROM web_sales
)
SELECT 
  combined.d_year,
  combined.cd_gender,
  combined.sm_code,
  combined.i_category,
  combined.sales_level,
  SUM(combined.total_sales) AS total_sales,
  AVG(combined.avg_discount) AS avg_discount,
  SUM(combined.order_cnt) AS total_orders,
  (SELECT AVG(cs.cs_ext_discount_amt)
     FROM catalog_sales cs
     JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
     WHERE d.d_year = 2001) AS overall_avg_discount,
  CASE 
    WHEN SUM(combined.total_sales) > 500000 THEN 'Platinum'
    WHEN SUM(combined.total_sales) > 200000 THEN 'Gold'
    ELSE 'Silver'
  END AS tier
FROM combined
WHERE combined.total_sales > 0
GROUP BY combined.d_year, combined.cd_gender, combined.sm_code, combined.i_category, combined.sales_level
HAVING SUM(combined.total_sales) > 10000
ORDER BY total_sales DESC
LIMIT 100
