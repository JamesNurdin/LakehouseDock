WITH store_sales_agg AS (
  SELECT ss.ss_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(ss.ss_net_paid) AS sales_net_paid
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY ss.ss_customer_sk, d.d_year
),
store_returns_agg AS (
  SELECT sr.sr_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(sr.sr_net_loss) AS returns_net_loss
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  GROUP BY sr.sr_customer_sk, d.d_year
),
web_sales_agg AS (
  SELECT ws.ws_bill_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(ws.ws_net_paid) AS sales_net_paid
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_bill_customer_sk, d.d_year
),
web_returns_agg AS (
  SELECT wr.wr_refunded_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(wr.wr_net_loss) AS returns_net_loss
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  GROUP BY wr.wr_refunded_customer_sk, d.d_year
),
catalog_sales_agg AS (
  SELECT cs.cs_bill_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(cs.cs_net_paid) AS sales_net_paid
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  GROUP BY cs.cs_bill_customer_sk, d.d_year
),
catalog_returns_agg AS (
  SELECT cr.cr_refunded_customer_sk AS customer_sk,
         d.d_year AS yr,
         SUM(cr.cr_net_loss) AS returns_net_loss
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  GROUP BY cr.cr_refunded_customer_sk, d.d_year
),
all_customers AS (
  SELECT customer_sk, yr FROM store_sales_agg
  UNION
  SELECT customer_sk, yr FROM store_returns_agg
  UNION
  SELECT customer_sk, yr FROM web_sales_agg
  UNION
  SELECT customer_sk, yr FROM web_returns_agg
  UNION
  SELECT customer_sk, yr FROM catalog_sales_agg
  UNION
  SELECT customer_sk, yr FROM catalog_returns_agg
)
SELECT
  cu.c_customer_id,
  cu.c_first_name,
  cu.c_last_name,
  cd.cd_gender,
  cd.cd_marital_status,
  COALESCE(ssa.sales_net_paid, 0) - COALESCE(sra.returns_net_loss, 0) +
  COALESCE(wa.sales_net_paid, 0) - COALESCE(wra.returns_net_loss, 0) +
  COALESCE(ca.sales_net_paid, 0) - COALESCE(cra.returns_net_loss, 0) AS net_revenue,
  ROW_NUMBER() OVER (
    ORDER BY (COALESCE(ssa.sales_net_paid, 0) - COALESCE(sra.returns_net_loss, 0) +
              COALESCE(wa.sales_net_paid, 0) - COALESCE(wra.returns_net_loss, 0) +
              COALESCE(ca.sales_net_paid, 0) - COALESCE(cra.returns_net_loss, 0)) DESC
  ) AS revenue_rank
FROM all_customers ac
LEFT JOIN store_sales_agg ssa ON ac.customer_sk = ssa.customer_sk AND ac.yr = ssa.yr
LEFT JOIN store_returns_agg sra ON ac.customer_sk = sra.customer_sk AND ac.yr = sra.yr
LEFT JOIN web_sales_agg wa ON ac.customer_sk = wa.customer_sk AND ac.yr = wa.yr
LEFT JOIN web_returns_agg wra ON ac.customer_sk = wra.customer_sk AND ac.yr = wra.yr
LEFT JOIN catalog_sales_agg ca ON ac.customer_sk = ca.customer_sk AND ac.yr = ca.yr
LEFT JOIN catalog_returns_agg cra ON ac.customer_sk = cra.customer_sk AND ac.yr = cra.yr
JOIN customer cu ON ac.customer_sk = cu.c_customer_sk
JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ac.yr = 2001
ORDER BY net_revenue DESC
LIMIT 100
