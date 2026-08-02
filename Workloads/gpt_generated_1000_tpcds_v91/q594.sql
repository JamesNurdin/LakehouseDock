WITH union_data AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    i.i_brand AS brand,
    p.p_promo_name AS promo_name,
    cs.cs_quantity AS quantity,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cm.cc_name AS partner_name
  FROM catalog_sales cs
  FULL OUTER JOIN call_center cm
    ON cs.cs_call_center_sk = cm.cc_call_center_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN customer cust
    ON cs.cs_bill_customer_sk = cust.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#23'
    AND cm.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND p.p_channel_email = 'N'

  UNION

  SELECT
    d.d_year AS year,
    i.i_category AS category,
    i.i_brand AS brand,
    p.p_promo_name AS promo_name,
    ss.ss_quantity AS quantity,
    ss.ss_ext_sales_price AS ext_sales_price,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    s.s_store_name AS partner_name
  FROM store_sales ss
  LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN customer cust
    ON ss.ss_customer_sk = cust.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND s.s_state = 'TX'
    AND cust.c_birth_month = 5
    AND cd.cd_gender = 'F'
)
SELECT
  year,
  category,
  brand,
  promo_name,
  partner_name,
  SUM(quantity) AS total_quantity,
  SUM(ext_sales_price) AS total_sales,
  AVG(net_paid) AS avg_net_paid,
  MAX(net_profit) AS max_net_profit,
  COUNT(*) AS transaction_count
FROM union_data
GROUP BY year, category, brand, promo_name, partner_name
ORDER BY total_sales DESC
LIMIT 100
