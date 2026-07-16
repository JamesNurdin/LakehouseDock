WITH
all_sales AS (
  SELECT 
    ss.ss_ticket_number AS order_number,
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_cdemo_sk AS cd_demo_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    'store' AS sales_channel,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_store_sk AS location_sk
  FROM store_sales ss
  UNION ALL
  SELECT 
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    'catalog' AS sales_channel,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_call_center_sk AS location_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT 
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    ws.ws_net_profit,
    'web' AS sales_channel,
    ws.ws_promo_sk AS promo_sk,
    ws.ws_web_page_sk AS location_sk
  FROM web_sales ws
),
all_returns AS (
  SELECT 
    sr.sr_ticket_number AS order_number,
    sr.sr_returned_date_sk AS return_date_sk,
    sr.sr_item_sk AS item_sk,
    sr.sr_customer_sk AS customer_sk,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss,
    'store' AS sales_channel
  FROM store_returns sr
  UNION ALL
  SELECT 
    cr.cr_order_number,
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cr.cr_refunded_customer_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    'catalog' AS sales_channel
  FROM catalog_returns cr
  UNION ALL
  SELECT 
    wr.wr_order_number,
    wr.wr_returned_date_sk,
    wr.wr_item_sk,
    wr.wr_refunded_customer_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    'web' AS sales_channel
  FROM web_returns wr
),
sales_with_returns AS (
  SELECT
    s.*,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.net_profit - COALESCE(r.total_net_loss, 0)) AS adj_net_profit
  FROM all_sales s
  LEFT JOIN (
    SELECT
      order_number,
      sales_channel,
      SUM(return_amount) AS total_return_amount,
      SUM(return_quantity) AS total_return_quantity,
      SUM(net_loss) AS total_net_loss
    FROM all_returns
    GROUP BY order_number, sales_channel
  ) r
    ON s.order_number = r.order_number AND s.sales_channel = r.sales_channel
),
customer_full AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(c.c_email_address, 'unknown@example.com') AS email,
    concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_credit_rating
  FROM customer c
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_details AS (
  SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_brand,
    i.i_category,
    i.i_class,
    i.i_color,
    i.i_size
  FROM item i
),
sales_enriched AS (
  SELECT
    swr.*,
    d.d_year,
    d.d_month_seq,
    d.d_week_seq,
    i.i_product_name AS product_name,
    i.i_brand AS brand,
    i.i_category AS category,
    i.i_class AS class,
    i.i_color AS color,
    i.i_size AS size,
    cust.full_name,
    cust.email,
    cust.c_preferred_cust_flag,
    cust.ca_city,
    cust.ca_state,
    cust.ca_country,
    cust.cd_gender,
    cust.cd_marital_status,
    cust.cd_credit_rating,
    p.p_promo_name,
    CASE 
      WHEN swr.sales_channel = 'store' THEN st.s_store_name
      WHEN swr.sales_channel = 'catalog' THEN cc.cc_name
      WHEN swr.sales_channel = 'web' THEN wp.wp_url
      ELSE NULL
    END AS location_name,
    CASE 
      WHEN swr.total_return_quantity > 0 THEN 'Returned'
      ELSE 'Completed'
    END AS order_status,
    CASE 
      WHEN swr.total_return_quantity = swr.quantity THEN 'FullReturn'
      WHEN swr.total_return_quantity > 0 THEN 'PartialReturn'
      ELSE 'NoReturn'
    END AS return_type,
    swr.adj_net_profit / NULLIF(swr.quantity, 0) AS profit_per_item,
    swr.adj_net_profit / NULLIF(swr.net_paid, 0) AS profit_margin,
    (SELECT AVG(s2.adj_net_profit)
     FROM sales_with_returns s2
     JOIN date_dim d2 ON s2.date_sk = d2.d_date_sk
     WHERE s2.sales_channel = swr.sales_channel
       AND s2.item_sk = swr.item_sk
       AND d2.d_year = d.d_year) AS avg_brand_year_profit,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY swr.adj_net_profit DESC) AS profit_rank_year
  FROM sales_with_returns swr
  LEFT JOIN date_dim d ON swr.date_sk = d.d_date_sk
  LEFT JOIN item_details i ON swr.item_sk = i.i_item_sk
  LEFT JOIN customer_full cust ON swr.customer_sk = cust.c_customer_sk
  LEFT JOIN promotion p ON swr.promo_sk = p.p_promo_sk
  LEFT JOIN store st ON (swr.sales_channel = 'store' AND swr.location_sk = st.s_store_sk)
  LEFT JOIN call_center cc ON (swr.sales_channel = 'catalog' AND swr.location_sk = cc.cc_call_center_sk)
  LEFT JOIN web_page wp ON (swr.sales_channel = 'web' AND swr.location_sk = wp.wp_web_page_sk)
)
SELECT
  year,
  sales_channel,
  location_name,
  full_name,
  email,
  product_name,
  brand,
  category,
  order_status,
  return_type,
  quantity,
  net_paid,
  total_return_amount,
  adj_net_profit,
  profit_per_item,
  profit_margin,
  avg_brand_year_profit,
  profit_rank_year
FROM (
  SELECT
    d_year AS year,
    sales_channel,
    location_name,
    full_name,
    email,
    product_name,
    brand,
    category,
    order_status,
    return_type,
    quantity,
    net_paid,
    total_return_amount,
    adj_net_profit,
    profit_per_item,
    profit_margin,
    avg_brand_year_profit,
    profit_rank_year
  FROM sales_enriched
) 
WHERE profit_rank_year <= 10
ORDER BY year DESC, sales_channel, profit_rank_year
