WITH
  store_agg AS (
    SELECT
      s.s_store_id AS store_id,
      i.i_brand AS brand,
      ib.ib_income_band_sk AS income_band_sk,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_minute IN (5, 13)
      AND t.t_sub_shift = 'morning'
      AND i.i_brand = 'exportiamalg #1'
      AND ib.ib_lower_bound >= 50000
      AND EXISTS (
        SELECT 1
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = sr.sr_item_sk
          AND cs.cs_quantity > 5
      )
    GROUP BY s.s_store_id, i.i_brand, ib.ib_income_band_sk
  ),
  web_agg AS (
    SELECT
      i.i_brand AS brand,
      ib.ib_income_band_sk AS income_band_sk,
      SUM(wr.wr_return_amt) AS total_web_return_amt,
      COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE t.t_minute = 8
      AND t.t_sub_shift = 'evening'
      AND i.i_brand = 'importoscholar #2'
      AND ib.ib_upper_bound <= 80000
    GROUP BY i.i_brand, ib.ib_income_band_sk
  ),
  combined AS (
    SELECT
      brand,
      income_band_sk,
      total_return_amt,
      return_cnt,
      CAST(NULL AS decimal(7,2)) AS total_web_return_amt,
      CAST(NULL AS integer) AS web_return_cnt
    FROM store_agg
    UNION ALL
    SELECT
      brand,
      income_band_sk,
      CAST(NULL AS decimal(7,2)) AS total_return_amt,
      CAST(NULL AS integer) AS return_cnt,
      total_web_return_amt,
      web_return_cnt
    FROM web_agg
  )
SELECT
  brand,
  income_band_sk,
  SUM(COALESCE(total_return_amt, 0) + COALESCE(total_web_return_amt, 0)) AS grand_total_return,
  SUM(COALESCE(return_cnt, 0) + COALESCE(web_return_cnt, 0)) AS grand_cnt,
  SUM(COALESCE(total_return_amt, 0) + COALESCE(total_web_return_amt, 0)) / NULLIF(SUM(COALESCE(return_cnt, 0) + COALESCE(web_return_cnt, 0)), 0) AS avg_return_amt
FROM combined
GROUP BY brand, income_band_sk
HAVING SUM(COALESCE(total_return_amt, 0) + COALESCE(total_web_return_amt, 0)) > 1000
ORDER BY grand_total_return DESC
LIMIT 100
