WITH filtered_customers AS (
  SELECT cd_demo_sk
  FROM customer_demographics
  WHERE cd_education_status = 'College'
    AND cd_gender = 'F'
),

catalog_returns_filtered AS (
  SELECT
    cr.*,
    r.r_reason_desc,
    r.r_reason_sk,
    sm.sm_type
  FROM catalog_returns cr
  JOIN filtered_customers fc ON cr.cr_refunded_cdemo_sk = fc.cd_demo_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
),

web_returns_filtered AS (
  SELECT
    wr.*,
    r.r_reason_desc,
    r.r_reason_sk
  FROM web_returns wr
  JOIN filtered_customers fc ON wr.wr_refunded_cdemo_sk = fc.cd_demo_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2452000
),

return_customers_by_reason AS (
  SELECT cr.r_reason_sk AS reason_sk, cr.r_reason_desc AS reason_desc, cr.cr_refunded_cdemo_sk AS cd_demo_sk
  FROM catalog_returns_filtered cr
  UNION ALL
  SELECT wr.r_reason_sk AS reason_sk, wr.r_reason_desc AS reason_desc, wr.wr_refunded_cdemo_sk AS cd_demo_sk
  FROM web_returns_filtered wr
),

sales_per_customer AS (
  SELECT
    ss.ss_cdemo_sk AS cd_demo_sk,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN filtered_customers fc ON ss.ss_cdemo_sk = fc.cd_demo_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY ss.ss_cdemo_sk
),

sales_agg_by_reason AS (
  SELECT
    rc.reason_sk,
    rc.reason_desc,
    SUM(spc.total_net_profit) AS total_sales_net_profit,
    COUNT(DISTINCT rc.cd_demo_sk) AS total_sales_customer_cnt
  FROM return_customers_by_reason rc
  JOIN sales_per_customer spc ON rc.cd_demo_sk = spc.cd_demo_sk
  GROUP BY rc.reason_sk, rc.reason_desc
),

catalog_return_agg AS (
  SELECT
    cr.sm_type AS ship_mode,
    cr.r_reason_sk AS reason_sk,
    cr.r_reason_desc AS reason_desc,
    COUNT(*) AS catalog_return_cnt,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    AVG(cr.cr_return_quantity) AS catalog_avg_return_qty,
    COUNT(DISTINCT cr.cr_refunded_cdemo_sk) AS catalog_customer_cnt
  FROM catalog_returns_filtered cr
  GROUP BY cr.sm_type, cr.r_reason_sk, cr.r_reason_desc
),

web_return_agg AS (
  SELECT
    wr.r_reason_sk AS reason_sk,
    wr.r_reason_desc AS reason_desc,
    COUNT(*) AS web_return_cnt,
    SUM(wr.wr_net_loss) AS web_net_loss,
    AVG(wr.wr_return_quantity) AS web_avg_return_qty,
    COUNT(DISTINCT wr.wr_refunded_cdemo_sk) AS web_customer_cnt
  FROM web_returns_filtered wr
  GROUP BY wr.r_reason_sk, wr.r_reason_desc
),

combined_return AS (
  SELECT
    COALESCE(ca.ship_mode, 'N/A') AS ship_mode,
    COALESCE(ca.reason_sk, wa.reason_sk) AS reason_sk,
    COALESCE(ca.reason_desc, wa.reason_desc) AS reason_desc,
    ca.catalog_return_cnt,
    ca.catalog_net_loss,
    ca.catalog_avg_return_qty,
    ca.catalog_customer_cnt,
    wa.web_return_cnt,
    wa.web_net_loss,
    wa.web_avg_return_qty,
    wa.web_customer_cnt
  FROM catalog_return_agg ca
  FULL OUTER JOIN web_return_agg wa
    ON ca.reason_sk = wa.reason_sk
)

SELECT
  cr.ship_mode,
  cr.reason_desc,
  COALESCE(cr.catalog_return_cnt, 0) AS catalog_return_cnt,
  COALESCE(cr.catalog_net_loss, 0) AS catalog_net_loss,
  COALESCE(cr.catalog_avg_return_qty, 0) AS catalog_avg_return_qty,
  COALESCE(cr.catalog_customer_cnt, 0) AS catalog_customer_cnt,
  COALESCE(cr.web_return_cnt, 0) AS web_return_cnt,
  COALESCE(cr.web_net_loss, 0) AS web_net_loss,
  COALESCE(cr.web_avg_return_qty, 0) AS web_avg_return_qty,
  COALESCE(cr.web_customer_cnt, 0) AS web_customer_cnt,
  COALESCE(sa.total_sales_net_profit, 0) AS total_sales_net_profit,
  COALESCE(sa.total_sales_customer_cnt, 0) AS total_sales_customer_cnt,
  ROW_NUMBER() OVER (PARTITION BY cr.ship_mode ORDER BY COALESCE(cr.catalog_net_loss, 0) DESC) AS ship_mode_rank
FROM combined_return cr
LEFT JOIN sales_agg_by_reason sa ON cr.reason_sk = sa.reason_sk
WHERE COALESCE(cr.catalog_net_loss, 0) > 5000 OR COALESCE(cr.web_net_loss, 0) > 5000
ORDER BY cr.ship_mode, cr.catalog_net_loss DESC
LIMIT 50
