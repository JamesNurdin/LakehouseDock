WITH base AS (
  SELECT
    d.d_year,
    ca.ca_state,
    i.i_category,
    hd.hd_income_band_sk,
    p.p_discount_active,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND ca.ca_state = 'CA'
    AND ca.ca_zip = '63951'
    AND i.i_brand = 'Brand#12'
    AND p.p_channel_press = 'N'
    AND inv.inv_quantity_on_hand > 0
    AND wr.wr_return_quantity = 0
  GROUP BY d.d_year, ca.ca_state, i.i_category, hd.hd_income_band_sk, p.p_discount_active
),

exclude AS (
  SELECT
    d.d_year,
    ca.ca_state,
    i.i_category,
    hd.hd_income_band_sk,
    p.p_discount_active,
    SUM(cs.cs_ext_sales_price) AS catalog_sales,
    SUM(ws.ws_ext_sales_price) AS web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END AS promo_active_flag
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
  WHERE d.d_year = 2000
    AND ca.ca_state = 'TX'
    AND ca.ca_zip = '75124'
    AND i.i_brand = 'Brand#23'
    AND p.p_channel_email = 'N'
    AND inv.inv_quantity_on_hand < 5
    AND wr.wr_return_quantity > 0
  GROUP BY d.d_year, ca.ca_state, i.i_category, hd.hd_income_band_sk, p.p_discount_active
)

SELECT *
FROM base
EXCEPT
SELECT *
FROM exclude
ORDER BY d_year DESC, catalog_sales DESC
LIMIT 100
