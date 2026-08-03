WITH sales_agg AS (
   SELECT
       cd.cd_demo_sk,
       cd.cd_credit_rating,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
   FROM
       catalog_sales cs TABLESAMPLE BERNOULLI (10)
       JOIN customer_demographics cd
         ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE
       cd.cd_credit_rating = 'Good'
       AND cd.cd_dep_count BETWEEN 1 AND 5
       AND cs.cs_quantity > 1
       AND cs.cs_ext_sales_price > 0
   GROUP BY
       cd.cd_demo_sk,
       cd.cd_credit_rating
), returns_agg AS (
   SELECT
       cd.cd_demo_sk,
       SUM(sr.sr_return_amt) AS total_returns,
       COUNT(*) AS returns_cnt
   FROM
       store_returns sr
       JOIN customer_demographics cd
         ON sr.sr_cdemo_sk = cd.cd_demo_sk
       JOIN store s
         ON sr.sr_store_sk = s.s_store_sk
       JOIN reason r
         ON sr.sr_reason_sk = r.r_reason_sk
   WHERE
       s.s_state = 'CA'
       AND sr.sr_return_quantity > 0
       AND cd.cd_credit_rating = 'Good'
       AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'
   GROUP BY
       cd.cd_demo_sk
), combined AS (
   SELECT
       sa.cd_demo_sk,
       sa.cd_credit_rating,
       sa.total_sales,
       sa.total_profit,
       sa.sales_cnt,
       COALESCE(ra.total_returns, 0) AS total_returns,
       COALESCE(ra.returns_cnt, 0) AS returns_cnt,
       (sa.total_sales - COALESCE(ra.total_returns, 0)) AS net_sales,
       (sa.total_profit / NULLIF(sa.total_sales, 0)) AS profit_margin
   FROM
       sales_agg sa
       LEFT JOIN returns_agg ra
         ON sa.cd_demo_sk = ra.cd_demo_sk
)
SELECT
   cd_demo_sk,
   cd_credit_rating,
   total_sales,
   total_returns,
   net_sales,
   profit_margin
FROM
   combined
WHERE
   profit_margin > (
       SELECT AVG(cs.cs_net_profit / NULLIF(cs.cs_ext_sales_price, 0))
       FROM catalog_sales cs
       WHERE cs.cs_ext_sales_price > 0
   )
   AND net_sales > 1000
   AND total_sales > 5000
   AND total_returns < 2000
   AND sales_cnt >= 10
ORDER BY
   net_sales DESC,
   profit_margin DESC
LIMIT 100
