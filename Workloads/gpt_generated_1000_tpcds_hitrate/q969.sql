WITH filtered_date AS (
  SELECT d_date_sk, d_year
  FROM date_dim
  WHERE d_year = 2001
),
base AS (
  SELECT
    d.d_year,
    i.i_item_id,
    i.i_brand,
    sm.sm_ship_mode_id,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    cs.cs_order_number,
    p.p_discount_active,
    inv.inv_quantity_on_hand
  FROM filtered_date d
  LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  RIGHT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE i.i_brand = 'Brand#23'
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand > 0
    AND cs.cs_quantity > 5
),
aggregated AS (
  SELECT
    d_year,
    i_item_id,
    i_brand,
    sm_ship_mode_id,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS order_cnt,
    CASE WHEN SUM(cs_quantity) > 100 THEN 'High' ELSE 'Low' END AS volume_category
  FROM base
  GROUP BY d_year, i_item_id, i_brand, sm_ship_mode_id
)
SELECT
  d_year,
  i_item_id,
  i_brand,
  sm_ship_mode_id,
  total_sales,
  avg_quantity,
  order_cnt,
  volume_category,
  RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
