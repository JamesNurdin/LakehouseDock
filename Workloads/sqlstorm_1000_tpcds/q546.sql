WITH unified_sales AS (
  SELECT
    s.s_state AS state,
    i.i_brand AS brand,
    date_trunc('quarter', d.d_date) AS quarter_start,
    'store' AS sales_channel,
    ss.ss_net_profit AS net_profit,
    ss.ss_net_paid AS net_paid,
    ss.ss_quantity AS quantity,
    ss.ss_ext_discount_amt AS discount_amount,
    ss.ss_ext_sales_price AS sales_price,
    ss.ss_customer_sk AS customer_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2000

  UNION ALL

  SELECT
    cc.cc_state AS state,
    i.i_brand AS brand,
    date_trunc('quarter', d.d_date) AS quarter_start,
    'catalog' AS sales_channel,
    cs.cs_net_profit AS net_profit,
    cs.cs_net_paid AS net_paid,
    cs.cs_quantity AS quantity,
    cs.cs_ext_discount_amt AS discount_amount,
    cs.cs_ext_sales_price AS sales_price,
    cs.cs_bill_customer_sk AS customer_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year BETWEEN 1999 AND 2000

  UNION ALL

  SELECT
    ca.ca_state AS state,
    i.i_brand AS brand,
    date_trunc('quarter', d.d_date) AS quarter_start,
    'web' AS sales_channel,
    ws.ws_net_profit AS net_profit,
    ws.ws_net_paid AS net_paid,
    ws.ws_quantity AS quantity,
    ws.ws_ext_discount_amt AS discount_amount,
    ws.ws_ext_sales_price AS sales_price,
    ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE d.d_year BETWEEN 1999 AND 2000
),

agg_sales AS (
  SELECT
    state,
    brand,
    quarter_start,
    sales_channel,
    SUM(net_profit) AS net_profit,
    SUM(net_paid) AS net_paid,
    SUM(quantity) AS total_quantity,
    SUM(discount_amount) AS total_discount,
    SUM(sales_price) AS total_sales_price,
    approx_distinct(customer_sk) AS distinct_customers
  FROM unified_sales
  WHERE state IS NOT NULL
  GROUP BY state, brand, quarter_start, sales_channel
)

SELECT
  state,
  brand,
  quarter_start,
  sales_channel,
  net_profit,
  LAG(net_profit) OVER (PARTITION BY state, brand, sales_channel ORDER BY quarter_start) AS prev_net_profit,
  net_profit - LAG(net_profit) OVER (PARTITION BY state, brand, sales_channel ORDER BY quarter_start) AS profit_growth,
  CASE
    WHEN LAG(net_profit) OVER (PARTITION BY state, brand, sales_channel ORDER BY quarter_start) = 0 THEN NULL
    ELSE (net_profit - LAG(net_profit) OVER (PARTITION BY state, brand, sales_channel ORDER BY quarter_start)) /
         LAG(net_profit) OVER (PARTITION BY state, brand, sales_channel ORDER BY quarter_start) * 100
  END AS profit_growth_pct,
  ROW_NUMBER() OVER (PARTITION BY quarter_start, sales_channel ORDER BY net_profit DESC) AS profit_rank,
  total_quantity,
  total_sales_price,
  total_discount,
  CASE WHEN total_sales_price = 0 THEN 0 ELSE total_discount / total_sales_price END AS avg_discount_rate,
  distinct_customers
FROM agg_sales
ORDER BY state, brand, quarter_start, sales_channel
