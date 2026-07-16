WITH store_monthly_sales AS (
   SELECT ss.ss_store_sk AS store_sk,
          d.d_year,
          d.d_month_seq,
          SUM(ss.ss_net_paid) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY ss.ss_store_sk, d.d_year, d.d_month_seq
),
store_monthly_returns AS (
   SELECT sr.sr_store_sk AS store_sk,
          d.d_year,
          d.d_month_seq,
          SUM(sr.sr_net_loss) AS total_returns,
          COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
store_combined AS (
   SELECT s.s_store_sk,
          s.s_store_name,
          s.s_city,
          d.d_year,
          d.d_month_seq,
          COALESCE(sms.total_sales, 0) AS total_sales,
          COALESCE(smr.total_returns, 0) AS total_returns
   FROM store s
   CROSS JOIN (
       SELECT d_year, d_month_seq
       FROM date_dim
       WHERE d_year BETWEEN 1999 AND 2002
   ) d
   LEFT JOIN store_monthly_sales sms
       ON s.s_store_sk = sms.store_sk
          AND sms.d_year = d.d_year
          AND sms.d_month_seq = d.d_month_seq
   LEFT JOIN store_monthly_returns smr
       ON s.s_store_sk = smr.store_sk
          AND smr.d_year = d.d_year
          AND smr.d_month_seq = d.d_month_seq
),
store_final AS (
   SELECT
       CONCAT(sc.s_store_name, ' - ', COALESCE(sc.s_city, 'UNKNOWN')) AS store_desc,
       sc.d_year,
       sc.d_month_seq,
       sc.total_sales,
       sc.total_returns,
       (sc.total_sales - sc.total_returns) AS net_contribution,
       CASE WHEN (sc.total_sales - sc.total_returns) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS contribution_flag,
       LAG(sc.total_sales - sc.total_returns) OVER (PARTITION BY CONCAT(sc.s_store_name, ' - ', COALESCE(sc.s_city, 'UNKNOWN')) ORDER BY sc.d_year, sc.d_month_seq) AS prev_month_contribution,
       (sc.total_sales - sc.total_returns) - COALESCE(LAG(sc.total_sales - sc.total_returns) OVER (PARTITION BY CONCAT(sc.s_store_name, ' - ', COALESCE(sc.s_city, 'UNKNOWN')) ORDER BY sc.d_year, sc.d_month_seq), 0) AS month_over_month_change,
       SUM(sc.total_sales - sc.total_returns) OVER (PARTITION BY CONCAT(sc.s_store_name, ' - ', COALESCE(sc.s_city, 'UNKNOWN')) ORDER BY sc.d_year, sc.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_contribution,
       (SELECT SUM(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = sc.d_year AND d2.d_month_seq = sc.d_month_seq) AS total_sales_all_stores_month
   FROM store_combined sc
   WHERE EXISTS (
       SELECT 1
       FROM catalog_sales cs
       JOIN date_dim d3 ON cs.cs_sold_date_sk = d3.d_date_sk
       WHERE d3.d_year = sc.d_year AND cs.cs_quantity > 10
   )
),
web_aggregated AS (
   SELECT
       CONCAT('WEB-', CAST(ws.ws_web_page_sk AS VARCHAR)) AS store_desc,
       d.d_year,
       d.d_month_seq,
       SUM(ws.ws_net_paid) AS total_sales,
       COALESCE(SUM(wr.wr_net_loss), 0) AS total_returns,
       SUM(ws.ws_net_paid) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_contribution,
       CASE WHEN SUM(ws.ws_net_paid) - COALESCE(SUM(wr.wr_net_loss), 0) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS contribution_flag,
       NULL AS prev_month_contribution,
       NULL AS month_over_month_change,
       SUM(ws.ws_net_paid) AS cumulative_net_contribution,
       NULL AS total_sales_all_stores_month
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
   GROUP BY ws.ws_web_page_sk, d.d_year, d.d_month_seq
)
SELECT *
FROM (
   SELECT *
   FROM store_final
   UNION ALL
   SELECT *
   FROM web_aggregated
) final_combined
ORDER BY net_contribution DESC
LIMIT 100
