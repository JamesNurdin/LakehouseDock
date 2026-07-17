WITH
store_sales_agg AS (
  SELECT
    ds.d_year,
    ds.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_net_profit) AS store_sales_net_profit
  FROM store_sales ss
  JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE ds.d_year = 2001
  GROUP BY ds.d_year, ds.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
store_returns_agg AS (
  SELECT
    dr.d_year,
    dr.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sr.sr_net_loss) AS store_returns_net_loss
  FROM store_returns sr
  JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE dr.d_year = 2001
  GROUP BY dr.d_year, dr.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
catalog_sales_agg AS (
  SELECT
    ds.d_year,
    ds.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.cs_net_profit) AS catalog_sales_net_profit
  FROM catalog_sales cs
  JOIN date_dim ds ON cs.cs_sold_date_sk = ds.d_date_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ds.d_year = 2001
  GROUP BY ds.d_year, ds.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
catalog_returns_agg AS (
  SELECT
    dr.d_year,
    dr.d_month_seq,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cr.cr_net_loss) AS catalog_returns_net_loss
  FROM catalog_returns cr
  JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  WHERE dr.d_year = 2001
  GROUP BY dr.d_year, dr.d_month_seq, cd.cd_gender, cd.cd_marital_status
),
combined AS (
  SELECT
    COALESCE(sa.d_year, ra.d_year, csa.d_year, cra.d_year) AS year,
    COALESCE(sa.d_month_seq, ra.d_month_seq, csa.d_month_seq, cra.d_month_seq) AS month_seq,
    COALESCE(sa.cd_gender, ra.cd_gender, csa.cd_gender, cra.cd_gender) AS gender,
    COALESCE(sa.cd_marital_status, ra.cd_marital_status, csa.cd_marital_status, cra.cd_marital_status) AS marital_status,
    COALESCE(sa.store_sales_net_profit, 0) - COALESCE(ra.store_returns_net_loss, 0) AS store_net_profit_adj,
    COALESCE(csa.catalog_sales_net_profit, 0) - COALESCE(cra.catalog_returns_net_loss, 0) AS catalog_net_profit_adj,
    (COALESCE(sa.store_sales_net_profit, 0) - COALESCE(ra.store_returns_net_loss, 0) +
     COALESCE(csa.catalog_sales_net_profit, 0) - COALESCE(cra.catalog_returns_net_loss, 0)) AS total_net_profit
  FROM store_sales_agg sa
  FULL OUTER JOIN store_returns_agg ra
    ON sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
    AND sa.cd_gender = ra.cd_gender
    AND sa.cd_marital_status = ra.cd_marital_status
  FULL OUTER JOIN catalog_sales_agg csa
    ON COALESCE(sa.d_year, ra.d_year) = csa.d_year
    AND COALESCE(sa.d_month_seq, ra.d_month_seq) = csa.d_month_seq
    AND COALESCE(sa.cd_gender, ra.cd_gender) = csa.cd_gender
    AND COALESCE(sa.cd_marital_status, ra.cd_marital_status) = csa.cd_marital_status
  FULL OUTER JOIN catalog_returns_agg cra
    ON COALESCE(sa.d_year, ra.d_year, csa.d_year) = cra.d_year
    AND COALESCE(sa.d_month_seq, ra.d_month_seq, csa.d_month_seq) = cra.d_month_seq
    AND COALESCE(sa.cd_gender, ra.cd_gender, csa.cd_gender) = cra.cd_gender
    AND COALESCE(sa.cd_marital_status, ra.cd_marital_status, csa.cd_marital_status) = cra.cd_marital_status
)
SELECT
  c.year,
  c.month_seq,
  c.gender,
  c.marital_status,
  c.total_net_profit,
  SUM(c.total_net_profit) OVER (PARTITION BY c.gender, c.marital_status ORDER BY c.year, c.month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
  LAG(c.total_net_profit) OVER (PARTITION BY c.gender, c.marital_status ORDER BY c.year, c.month_seq) AS prev_month_profit,
  c.total_net_profit - LAG(c.total_net_profit) OVER (PARTITION BY c.gender, c.marital_status ORDER BY c.year, c.month_seq) AS mom_change,
  RANK() OVER (PARTITION BY c.year, c.month_seq ORDER BY c.total_net_profit DESC) AS profit_rank
FROM combined c
ORDER BY c.gender, c.marital_status, c.year, c.month_seq
