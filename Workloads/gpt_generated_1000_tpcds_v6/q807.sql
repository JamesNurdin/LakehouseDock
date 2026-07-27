WITH
  sales_agg AS (
    SELECT
      cs.cs_ship_date_sk AS date_sk,
      SUM(cs.cs_ext_sales_price) AS amount,
      'sales' AS source
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type = 'AIR'
      AND cd.cd_dep_employed_count >= 2
    GROUP BY cs.cs_ship_date_sk
  ),
  returns_agg AS (
    SELECT
      wr.wr_returned_date_sk AS date_sk,
      SUM(wr.wr_return_amt) AS amount,
      'returns' AS source
    FROM web_returns wr
    JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE r.r_reason_desc LIKE '%damaged%'
      AND wp.wp_type = 'home'
    GROUP BY wr.wr_returned_date_sk
  )
SELECT date_sk, amount, source
FROM sales_agg
UNION ALL
SELECT date_sk, amount, source
FROM returns_agg
ORDER BY date_sk DESC, source ASC
LIMIT 100
