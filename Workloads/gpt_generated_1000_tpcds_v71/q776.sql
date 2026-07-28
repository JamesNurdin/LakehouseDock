WITH sub_a AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_county,
    cc.cc_company,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sale_date_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
  FROM store_returns sr
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE s.s_county = 'Raleigh County'
    AND cc.cc_company = 4
    AND s.s_rec_start_date >= DATE '1999-01-01'
    AND EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_autogen_flag = 'Y'
    )
  GROUP BY s.s_store_id, s.s_store_name, s.s_county, cc.cc_company
  HAVING SUM(cs.cs_ext_sales_price) > 100000
),
sub_b AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_county,
    cc.cc_company,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cs.cs_quantity) AS avg_quantity,
    MIN(cs.cs_sold_date_sk) AS first_sale_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sale_date_sk,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
  FROM store_returns sr
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE s.s_county = 'Dauphin County'
    AND cc.cc_company = 2
    AND s.s_rec_start_date >= DATE '2000-01-01'
    AND EXISTS (
      SELECT 1 FROM web_page wp
      WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_autogen_flag = 'N'
    )
  GROUP BY s.s_store_id, s.s_store_name, s.s_county, cc.cc_company
  HAVING SUM(cs.cs_ext_sales_price) > 150000
)
SELECT *
FROM sub_a
UNION ALL
SELECT *
FROM sub_b
ORDER BY total_sales DESC
LIMIT 100
