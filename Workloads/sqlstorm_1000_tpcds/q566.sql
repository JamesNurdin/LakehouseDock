WITH sales_store AS (
  SELECT
    ss.ss_sold_date_sk AS sold_date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_customer_sk AS customer_sk,
    ss.ss_cdemo_sk AS cdemo_sk,
    ss.ss_hdemo_sk AS hdemo_sk,
    ss.ss_promo_sk AS promo_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_discount_amt AS discount_amt,
    ss.ss_ext_sales_price AS ext_sales_price,
    d.d_year,
    d.d_month_seq,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    i.i_category,
    i.i_class,
    i.i_brand,
    'store' AS channel
  FROM store_sales ss
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
sales_catalog AS (
  SELECT
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_bill_customer_sk AS customer_sk,
    cs.cs_bill_cdemo_sk AS cdemo_sk,
    cs.cs_bill_hdemo_sk AS hdemo_sk,
    cs.cs_promo_sk AS promo_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_ext_sales_price AS ext_sales_price,
    d.d_year,
    d.d_month_seq,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    i.i_category,
    i.i_class,
    i.i_brand,
    'catalog' AS channel
  FROM catalog_sales cs
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
sales_web AS (
  SELECT
    ws.ws_sold_date_sk AS sold_date_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_bill_customer_sk AS customer_sk,
    ws.ws_bill_cdemo_sk AS cdemo_sk,
    ws.ws_bill_hdemo_sk AS hdemo_sk,
    ws.ws_promo_sk AS promo_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_ext_sales_price AS ext_sales_price,
    d.d_year,
    d.d_month_seq,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    i.i_category,
    i.i_class,
    i.i_brand,
    'web' AS channel
  FROM web_sales ws
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
combined_sales AS (
  SELECT * FROM sales_store
  UNION ALL
  SELECT * FROM sales_catalog
  UNION ALL
  SELECT * FROM sales_web
),
returns_union AS (
  SELECT
    sr.sr_customer_sk AS customer_sk,
    sr.sr_returned_date_sk AS returned_date_sk,
    sr.sr_item_sk AS item_sk,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_return_amt AS return_amount,
    d.d_year AS return_year
  FROM store_returns sr
  LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    cr.cr_returning_customer_sk AS customer_sk,
    cr.cr_returned_date_sk AS returned_date_sk,
    cr.cr_item_sk AS item_sk,
    cr.cr_return_quantity AS return_quantity,
    cr.cr_return_amount AS return_amount,
    d.d_year AS return_year
  FROM catalog_returns cr
  LEFT JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  UNION ALL
  SELECT
    wr.wr_refunded_customer_sk AS customer_sk,
    wr.wr_returned_date_sk AS returned_date_sk,
    wr.wr_item_sk AS item_sk,
    wr.wr_return_quantity AS return_quantity,
    wr.wr_return_amt AS return_amount,
    d.d_year AS return_year
  FROM web_returns wr
  LEFT JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
),
brand_buyers AS (
  SELECT DISTINCT cs.customer_sk
  FROM combined_sales cs
  WHERE cs.i_brand = 'BrandX'
),
return_customers AS (
  SELECT DISTINCT customer_sk FROM returns_union
),
brand_buyers_intersect_returns AS (
  SELECT customer_sk FROM brand_buyers
  INTERSECT
  SELECT customer_sk FROM return_customers
),
customer_sales AS (
  SELECT
    customer_sk,
    channel,
    d_year,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    SUM(quantity) AS total_quantity,
    AVG(CASE WHEN ext_sales_price > 0 THEN discount_amt / ext_sales_price ELSE 0 END) AS avg_discount_rate,
    COUNT(*) AS transaction_count
  FROM combined_sales
  GROUP BY customer_sk, channel, d_year
),
customer_returns AS (
  SELECT
    customer_sk,
    COUNT(*) AS total_returns,
    SUM(return_amount) AS total_return_amount
  FROM returns_union
  GROUP BY customer_sk
),
customer_metrics AS (
  SELECT
    cs.customer_sk,
    cs.channel,
    cs.d_year,
    cs.total_net_paid,
    cs.total_net_profit,
    cs.total_quantity,
    cs.avg_discount_rate,
    cs.transaction_count,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE WHEN cs.total_net_profit > 0 THEN 'PROFITABLE' ELSE 'UNPROFITABLE' END AS profit_status,
    concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
    CASE WHEN cs.total_net_paid > 10000 THEN 1 ELSE 0 END AS high_spender_flag,
    (SELECT AVG(net_profit)
       FROM combined_sales cs2
       WHERE cs2.customer_sk = cs.customer_sk
         AND cs2.d_year = cs.d_year) AS avg_customer_yearly_profit,
    RANK() OVER (PARTITION BY cs.channel, cs.d_year ORDER BY cs.total_net_profit DESC) AS profit_rank
  FROM customer_sales cs
  LEFT JOIN customer c ON cs.customer_sk = c.c_customer_sk
  LEFT JOIN customer_returns cr ON cs.customer_sk = cr.customer_sk
)
SELECT
  cm.customer_sk,
  cm.full_name,
  cm.channel,
  cm.d_year,
  cm.total_net_paid,
  cm.total_net_profit,
  cm.total_quantity,
  ROUND(cm.avg_discount_rate * 100, 2) AS avg_discount_pct,
  cm.transaction_count,
  cm.total_returns,
  cm.total_return_amount,
  cm.profit_status,
  cm.high_spender_flag,
  ROUND(cm.avg_customer_yearly_profit, 2) AS avg_customer_yearly_profit,
  cm.profit_rank
FROM customer_metrics cm
WHERE cm.customer_sk IN (SELECT customer_sk FROM brand_buyers_intersect_returns)
  AND cm.profit_rank <= 10
ORDER BY cm.channel, cm.d_year DESC, cm.profit_rank
