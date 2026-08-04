WITH sales_agg AS (
   SELECT d.d_year,
          s.s_store_name,
          SUM(ss.ss_net_paid) AS total_sales
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY d.d_year, s.s_store_name
),
returns_agg AS (
   SELECT d.d_year,
          s.s_store_name,
          -SUM(sr.sr_net_loss) AS total_sales
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   GROUP BY d.d_year, s.s_store_name
),
union_sales AS (
   SELECT * FROM sales_agg
   UNION ALL
   SELECT * FROM returns_agg
),
catalog_agg AS (
   SELECT d.d_year,
          r.r_reason_desc,
          SUM(cr.cr_return_amount) AS total_return_amount
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   GROUP BY d.d_year, r.r_reason_desc
)
SELECT
   us.d_year,
   us.s_store_name,
   us.total_sales,
   ca.r_reason_desc,
   ca.total_return_amount,
   rc.reason_count,
   ROW_NUMBER() OVER (ORDER BY us.total_sales DESC) AS rn
FROM union_sales us
FULL OUTER JOIN catalog_agg ca
   ON us.d_year = ca.d_year
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS reason_count
   FROM reason r2
   WHERE r2.r_reason_desc LIKE '%' || us.s_store_name || '%'
) rc
WHERE us.total_sales IS NOT NULL OR ca.total_return_amount IS NOT NULL
ORDER BY rn
OFFSET 0 LIMIT 100
