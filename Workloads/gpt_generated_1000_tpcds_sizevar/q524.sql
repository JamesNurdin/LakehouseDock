WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows
  ),
  filtered_sales AS (
    SELECT ss.*
    FROM sampled_sales ss
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_net_paid > (
        SELECT avg(ss2.ss_net_paid)
        FROM store_sales ss2
      )
      AND ss.ss_cdemo_sk IN (
        SELECT cd.cd_demo_sk
        FROM customer_demographics cd
        WHERE cd.cd_marital_status = 'S'
          AND cd.cd_credit_rating = 'Good'
      )
  ),
  store_keys AS (
    SELECT s.s_store_sk
    FROM store s
    WHERE s.s_geography_class = 'Unknown'
  ),
  intersected_keys AS (
    SELECT s_store_sk FROM store_keys
    INTERSECT
    SELECT ss_store_sk FROM filtered_sales
  ),
  joined AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_cdemo_sk,
      ss.ss_ext_sales_price,
      ss.ss_net_paid,
      cd.cd_gender,
      cd.cd_credit_rating,
      s.s_state,
      s.s_market_desc,
      s.s_market_id
    FROM filtered_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_store_sk IN (SELECT s_store_sk FROM intersected_keys)
  ),
  lateral_agg AS (
    SELECT
      j.*, 
      la.max_net_paid
    FROM joined j
    LEFT JOIN LATERAL (
      SELECT max(ss2.ss_net_paid) AS max_net_paid
      FROM store_sales ss2
      WHERE ss2.ss_store_sk = j.ss_store_sk
    ) la ON true
  )
SELECT
  s_state,
  s_market_desc,
  cd_gender,
  COUNT(*) AS sales_cnt,
  SUM(ss_ext_sales_price) AS total_ext_sales,
  AVG(ss_net_paid) AS avg_net_paid,
  MAX(max_net_paid) AS store_max_net_paid
FROM lateral_agg
GROUP BY s_state, s_market_desc, cd_gender
ORDER BY total_ext_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
