WITH
  store_sales_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_city,
      s.s_state,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt,
      ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(ss.ss_net_paid) DESC) AS state_store_rank
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE s.s_state LIKE 'N%'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
    HAVING SUM(ss.ss_net_paid) > 10000
  ),

  catalog_reason AS (
    SELECT
      cr.cr_reason_sk,
      r.r_reason_desc,
      cr.cr_return_amount,
      cr.cr_return_quantity
    FROM catalog_returns cr
    FULL OUTER JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc IS NOT NULL
  ),

  web_reason AS (
    SELECT
      wr.wr_reason_sk,
      r.r_reason_desc,
      wr.wr_return_amt,
      wr.wr_return_quantity
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage')
  ),

  combined_returns AS (
    SELECT cr_reason_sk AS reason_sk,
           r_reason_desc,
           SUM(cr_return_amount) AS total_amount
    FROM catalog_reason
    GROUP BY cr_reason_sk, r_reason_desc
    UNION ALL
    SELECT wr_reason_sk,
           r_reason_desc,
           SUM(wr_return_amt)
    FROM web_reason
    GROUP BY wr_reason_sk, r_reason_desc
  ),

  filtered_combined AS (
    SELECT DISTINCT reason_sk,
                    r_reason_desc,
                    total_amount
    FROM combined_returns
    WHERE total_amount > 5000
  ),

  final_reasons AS (
    SELECT reason_sk FROM filtered_combined
    EXCEPT
    SELECT wr_reason_sk FROM web_reason
  )

SELECT
  ss.s_store_name,
  ss.s_city,
  ss.total_net_paid,
  ss.sales_cnt,
  ss.state_store_rank,
  lt.name_number,
  (SELECT COUNT(*) FROM final_reasons fr WHERE fr.reason_sk = ss.s_store_sk) AS matching_reason_cnt
FROM store_sales_agg ss
CROSS JOIN LATERAL (
  SELECT regexp_extract(ss.s_store_name, '(\\d+)$', 1) AS name_number
) lt
WHERE regexp_like(ss.s_store_name, '^Store')
ORDER BY ss.total_net_paid DESC
LIMIT 100
