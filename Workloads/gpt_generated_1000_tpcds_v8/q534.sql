WITH
catalog_part AS (
  SELECT
    cs.cs_order_number,
    d.d_date,
    cs.cs_ext_sales_price AS sales_amount,
    i.i_item_id,
    i.i_brand,
    p.p_promo_id,
    c.c_customer_id,
    ca.ca_state,
    cp.cp_department,
    cp.cp_type,
    ib.ib_upper_bound
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2000
    AND p.p_channel_tv = 'N'
    AND i.i_brand = 'Brand#12'
    AND ib.ib_upper_bound > 50000
),
store_part AS (
  SELECT
    ss.ss_ticket_number,
    d.d_date,
    ss.ss_ext_sales_price AS sales_amount,
    i.i_item_id,
    i.i_brand,
    p.p_promo_id,
    c.c_customer_id,
    ca.ca_state,
    s.s_state,
    r.r_reason_desc,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    ib.ib_upper_bound
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2000
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND i.i_color = 'Red'
),
web_part AS (
  SELECT
    ws.ws_order_number,
    d.d_date,
    ws.ws_ext_sales_price AS sales_amount,
    i.i_item_id,
    i.i_brand,
    p.p_promo_id,
    c.c_customer_id,
    ca.ca_state,
    ib.ib_upper_bound,
    r.r_reason_desc,
    wr.wr_return_quantity,
    wr.wr_return_amt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2000
    AND p.p_channel_email = 'Y'
    AND i.i_size = 'M'
    AND ca.ca_state = 'TX'
)
SELECT
  COALESCE(ua.order_number, wp.ws_order_number) AS order_number,
  COALESCE(ua.d_date, wp.d_date) AS sale_date,
  COALESCE(ua.sales_amount, wp.sales_amount) AS sales_amount,
  COALESCE(ua.i_item_id, wp.i_item_id) AS item_id,
  COALESCE(ua.i_brand, wp.i_brand) AS brand,
  COALESCE(ua.p_promo_id, wp.p_promo_id) AS promo_id,
  COALESCE(ua.c_customer_id, wp.c_customer_id) AS customer_id,
  COALESCE(ua.state, wp.ca_state) AS state,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(ua.state, wp.ca_state) ORDER BY COALESCE(ua.sales_amount, wp.sales_amount) DESC) AS sales_rank
FROM (
  SELECT
    cs_order_number AS order_number,
    d_date,
    sales_amount,
    i_item_id,
    i_brand,
    p_promo_id,
    c_customer_id,
    ca_state AS state
  FROM catalog_part
  UNION
  SELECT
    ss_ticket_number AS order_number,
    d_date,
    sales_amount,
    i_item_id,
    i_brand,
    p_promo_id,
    c_customer_id,
    s_state AS state
  FROM store_part
) ua
FULL OUTER JOIN web_part wp
  ON ua.order_number = wp.ws_order_number
WHERE COALESCE(ua.order_number, wp.ws_order_number) NOT IN (
      SELECT ws_order_number FROM web_sales WHERE ws_quantity > 50
)
ORDER BY sales_rank
LIMIT 100
