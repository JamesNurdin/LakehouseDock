WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      s.s_store_name,
      cd.cd_gender,
      t.t_hour,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      AVG(ss.ss_ext_discount_amt) AS avg_discount,
      COUNT(*) AS sales_cnt,
      (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = ss.ss_store_sk
      ) AS avg_store_sales
    FROM store_sales ss
    FULL OUTER JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND cd.cd_dep_count <= 2
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_store_sk, s.s_store_name, cd.cd_gender, t.t_hour
  ),
  web_agg AS (
    SELECT
      wr.wr_returned_time_sk AS time_sk,
      cd2.cd_gender AS gender,
      t2.t_hour,
      SUM(wr.wr_return_amt) AS total_returns,
      AVG(wr.wr_return_tax) AS avg_return_tax,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN time_dim t2
      ON wr.wr_returned_time_sk = t2.t_time_sk
    JOIN customer_demographics cd2
      ON wr.wr_refunded_cdemo_sk = cd2.cd_demo_sk
    WHERE wr.wr_return_amt > 500
      AND cd2.cd_dep_count = 0
      AND t2.t_hour >= 12
    GROUP BY wr.wr_returned_time_sk, cd2.cd_gender, t2.t_hour
  ),
  union_set AS (
    SELECT ss_store_sk AS key_id, total_sales AS metric, 'sales'   AS src FROM sales_agg
    UNION
    SELECT time_sk    AS key_id, total_returns AS metric, 'returns' AS src FROM web_agg
  )
SELECT
  key_id,
  metric,
  src,
  ROW_NUMBER() OVER (PARTITION BY src ORDER BY metric DESC) AS rank_by_src
FROM (
  SELECT key_id, metric, src FROM union_set
  EXCEPT
  SELECT key_id, metric, src FROM (
    SELECT ss_store_sk AS key_id, total_sales AS metric, 'sales' AS src
    FROM sales_agg
    WHERE total_sales > 20000
  ) excl
) final_set
LIMIT 100
