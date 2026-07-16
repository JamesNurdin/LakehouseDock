WITH
sales_union AS (
  SELECT cs.cs_sold_date_sk AS sale_date_sk,
         cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_ext_sales_price AS sales_amount,
         cs.cs_net_profit AS profit_amount,
         cs.cs_item_sk AS item_sk,
         'catalog' AS channel,
         cs.cs_order_number AS order_number
  FROM catalog_sales cs
  WHERE cs.cs_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_customer_sk,
         ss.ss_ext_sales_price,
         ss.ss_net_profit,
         ss.ss_item_sk,
         'store',
         ss.ss_ticket_number
  FROM store_sales ss
  WHERE ss.ss_sold_date_sk IS NOT NULL
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_bill_customer_sk,
         ws.ws_ext_sales_price,
         ws.ws_net_profit,
         ws.ws_item_sk,
         'web',
         ws.ws_order_number
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk IS NOT NULL
),
sales_agg AS (
  SELECT 
    su.customer_sk,
    SUM(su.sales_amount) AS total_sales,
    SUM(su.profit_amount) AS total_profit,
    COUNT(*) AS txn_count,
    COUNT(DISTINCT su.item_sk) AS distinct_items,
    MIN(su.sale_date_sk) AS first_sale_date_sk,
    MAX(su.sale_date_sk) AS last_sale_date_sk,
    SUM(su.sales_amount) FILTER (WHERE su.profit_amount > 0) AS sales_positive_profit,
    SUM(su.sales_amount) FILTER (WHERE su.profit_amount <= 0) AS sales_nonpositive_profit,
    SUM(su.sales_amount) / NULLIF(COUNT(*), 0) AS avg_sale_amount,
    MAX(su.profit_amount) AS max_profit,
    MIN(su.profit_amount) AS min_profit
  FROM sales_union su
  GROUP BY su.customer_sk
),
peak_item AS (
  SELECT 
    su.customer_sk,
    i.i_item_id,
    su.item_sk,
    su.profit_amount,
    ROW_NUMBER() OVER (PARTITION BY su.customer_sk ORDER BY su.profit_amount DESC NULLS LAST) AS rn
  FROM sales_union su
  JOIN item i ON i.i_item_sk = su.item_sk
),
customer_peak_item AS (
  SELECT 
    customer_sk,
    i_item_id,
    profit_amount AS peak_profit
  FROM peak_item
  WHERE rn = 1
),
demo_info AS (
  SELECT 
    c.c_customer_sk,
    COALESCE(cd.cd_purchase_estimate, -1) AS purchase_estimate,
    COALESCE(hd.hd_income_band_sk, -1) AS income_band_sk,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper,
    cd.cd_gender,
    hd.hd_buy_potential
  FROM customer c
  LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
  LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
  LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
),
churn_risk AS (
  SELECT 
    di.c_customer_sk,
    CASE 
      WHEN di.purchase_estimate IS NULL THEN 'UNKNOWN'
      WHEN di.purchase_estimate < 50 THEN 'LOW'
      WHEN di.purchase_estimate BETWEEN 50 AND 200 THEN 'MEDIUM'
      ELSE 'HIGH'
    END AS risk_category,
    CASE 
      WHEN di.income_lower >= 0 AND di.income_upper > 100000 THEN 1
      ELSE 0
    END AS high_income_flag
  FROM demo_info di
),
customers_all_channels AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk FROM catalog_sales cs
  INTERSECT
  SELECT ss.ss_customer_sk FROM store_sales ss
  INTERSECT
  SELECT ws.ws_bill_customer_sk FROM web_sales ws
),
catalog_return_stats AS (
  SELECT 
    cr.cr_returning_customer_sk AS customer_sk,
    COUNT(*) AS catalog_return_cnt,
    MAX(cr.cr_return_amount) AS catalog_max_return
  FROM catalog_returns cr
  GROUP BY cr.cr_returning_customer_sk
),
web_return_counts AS (
  SELECT 
    wr.wr_refunded_customer_sk AS customer_sk,
    COUNT(*) AS web_return_cnt
  FROM web_returns wr
  GROUP BY wr.wr_refunded_customer_sk
),
customer_activity_window AS (
  SELECT 
    sa.customer_sk,
    d_first.d_date AS first_sale_date,
    d_last.d_date AS last_sale_date,
    DATE_DIFF('day', d_first.d_date, d_last.d_date) AS activity_span_days
  FROM sales_agg sa
  LEFT JOIN date_dim d_first ON d_first.d_date_sk = sa.first_sale_date_sk
  LEFT JOIN date_dim d_last ON d_last.d_date_sk = sa.last_sale_date_sk
),
agg_by_demo_gender AS (
  SELECT 
    di.cd_gender,
    di.hd_buy_potential,
    SUM(COALESCE(sa.total_sales,0)) AS sum_sales,
    AVG(COALESCE(sa.total_profit,0)) AS avg_profit,
    GROUPING(di.cd_gender) AS grp_gender,
    GROUPING(di.hd_buy_potential) AS grp_buy_pot
  FROM sales_agg sa
  JOIN demo_info di ON di.c_customer_sk = sa.customer_sk
  GROUP BY GROUPING SETS (
    (di.cd_gender, di.hd_buy_potential),
    (di.cd_gender),
    (di.hd_buy_potential),
    ()
  )
)
SELECT 
  c.c_customer_id,
  COALESCE(sa.total_sales,0) AS total_sales,
  COALESCE(sa.total_profit,0) AS total_profit,
  COALESCE(sa.txn_count,0) AS transaction_count,
  COALESCE(sa.distinct_items,0) AS distinct_items,
  COALESCE(cp.peak_profit,0) AS peak_item_profit,
  COALESCE(cp.i_item_id,'NONE') AS peak_item_id,
  crk.risk_category,
  CASE WHEN crk.high_income_flag = 1 THEN 'YES' ELSE 'NO' END AS high_income_customer,
  COALESCE(wrc.web_return_cnt,0) AS web_return_count,
  COALESCE(crs.catalog_return_cnt,0) AS catalog_return_count,
  COALESCE(crs.catalog_max_return,0) AS catalog_max_return_amount,
  CASE WHEN cac.customer_sk IS NOT NULL THEN 'YES' ELSE 'NO' END AS all_channels_flag,
  aw.first_sale_date,
  aw.last_sale_date,
  aw.activity_span_days,
  CASE 
    WHEN aw.activity_span_days IS NOT NULL THEN 
      aw.activity_span_days / NULLIF(DATE_DIFF('day', DATE '2000-01-01', DATE '2024-10-01'),0)
    ELSE NULL
  END AS activity_span_ratio,
  CONCAT(COALESCE(c.c_first_name,''), ' ', COALESCE(c.c_last_name,'')) AS full_name,
  UPPER(c.c_login) AS login_upper,
  SUBSTRING(COALESCE(c.c_email_address,''),1,5) AS email_prefix,
  REGEXP_LIKE(COALESCE(c.c_email_address,''), '^.*@.*\\.com$') AS is_com_email,
  ROW_NUMBER() OVER (ORDER BY COALESCE(sa.total_profit,0) DESC NULLS LAST) AS profit_rank,
  RANK() OVER (PARTITION BY crk.risk_category ORDER BY COALESCE(sa.total_sales,0) DESC) AS risk_sales_rank,
  CASE 
    WHEN COALESCE(sa.total_profit,0) > 0 AND COALESCE(sa.total_sales,0) > 1000 THEN 'PROFITABLE'
    WHEN COALESCE(sa.total_profit,0) <= 0 THEN 'LOSS'
    ELSE 'NEUTRAL'
  END AS profit_flag,
  COALESCE((
    SELECT AVG(ws.ws_net_profit)
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
  ),0) AS avg_web_profit,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_amt > 0
    ) THEN 'YES' ELSE 'NO' END AS has_store_return,
  CASE 
    WHEN COALESCE(sa.total_sales,0) IS DISTINCT FROM 0 THEN 
      COALESCE(sa.total_sales,0) / NULLIF(COALESCE(sa.txn_count,0),0)
    ELSE NULL
  END AS avg_sale_per_txn,
  CASE 
    WHEN COALESCE(aw.activity_span_days,0) > 30 THEN 'ACTIVE' ELSE 'INACTIVE' END AS activity_status,
  CASE 
    WHEN crk.risk_category = 'HIGH' AND crk.high_income_flag = 1 THEN 'VIP' ELSE 'REGULAR' END AS customer_segment
FROM customer c
LEFT JOIN sales_agg sa ON sa.customer_sk = c.c_customer_sk
LEFT JOIN customer_peak_item cp ON cp.customer_sk = c.c_customer_sk
LEFT JOIN demo_info di ON di.c_customer_sk = c.c_customer_sk
LEFT JOIN churn_risk crk ON crk.c_customer_sk = c.c_customer_sk
LEFT JOIN customers_all_channels cac ON cac.customer_sk = c.c_customer_sk
LEFT JOIN catalog_return_stats crs ON crs.customer_sk = c.c_customer_sk
LEFT JOIN web_return_counts wrc ON wrc.customer_sk = c.c_customer_sk
LEFT JOIN customer_activity_window aw ON aw.customer_sk = c.c_customer_sk
WHERE 
  (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
  AND COALESCE(sa.total_sales,0) > 500
  AND (c.c_birth_year IS NOT NULL AND c.c_birth_year BETWEEN 1950 AND 2000)
  AND NOT (c.c_last_name LIKE 'Z%')
  AND crk.risk_category IS NOT NULL
ORDER BY total_profit DESC
LIMIT 100
