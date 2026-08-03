WITH raw_a AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_promo_sk,
    cs.cs_net_paid_inc_ship,
    ws.ws_net_paid_inc_ship,
    sr.sr_net_loss,
    d.d_year,
    d.d_date,
    t.t_shift,
    ib.ib_lower_bound,
    p.p_promo_name,
    CASE WHEN cs.cs_net_paid_inc_ship > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND t.t_shift = 'first'
    AND ib.ib_lower_bound >= 30000
),
raw_b AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_promo_sk,
    cs.cs_net_paid_inc_ship,
    ws.ws_net_paid_inc_ship,
    sr.sr_net_loss,
    d.d_year,
    d.d_date,
    t.t_shift,
    ib.ib_lower_bound,
    p.p_promo_name,
    CASE WHEN cs.cs_net_paid_inc_ship > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND t.t_shift = 'second'
    AND ib.ib_lower_bound >= 30000
),
union_raw AS (
  SELECT * FROM raw_a
  UNION DISTINCT
  SELECT * FROM raw_b
),
agg AS (
  SELECT
    d_year,
    p_promo_name,
    sales_category,
    SUM(cs_net_paid_inc_ship) AS total_catalog_sales,
    SUM(ws_net_paid_inc_ship) AS total_web_sales,
    SUM(sr_net_loss) AS total_return_loss
  FROM union_raw
  GROUP BY GROUPING SETS (
    (d_year, p_promo_name, sales_category),
    (d_year, sales_category),
    (d_year)
  )
)
SELECT
  d_year,
  p_promo_name,
  sales_category,
  total_catalog_sales,
  total_web_sales,
  total_return_loss,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank
FROM agg
ORDER BY d_year DESC, sales_rank
LIMIT 100
