WITH
  page_returns AS (
    SELECT
      wp.wp_web_page_id,
      wp.wp_type,
      wp.wp_max_ad_count,
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      wr.wr_returned_date_sk,
      CONCAT(wp.wp_url, '/', wp.wp_type) AS full_url,
      CASE
        WHEN regexp_like(wp.wp_url, '^https?://(www\.)?') THEN 'http'
        ELSE 'other'
      END AS url_scheme
    FROM web_page wp
    FULL OUTER JOIN web_returns wr
      ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE wp.wp_type LIKE 'C%'
      AND regexp_like(wp.wp_url, '\\.com$')
  ),
  demo_returns AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_dep_employed_count,
      cd.cd_dep_college_count,
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_return_quantity,
      regexp_extract(cast(wr.wr_reason_sk AS varchar), '(\\d+)', 1) AS reason_code
    FROM web_returns wr
    FULL OUTER JOIN customer_demographics cd
      ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IN ('M', 'S')
      AND cd.cd_dep_employed_count > 0
  )
SELECT
  src,
  SUM(return_amt) AS total_return_amt,
  COUNT(*) AS cnt
FROM (
  SELECT 'page' AS src, wr_return_amt AS return_amt
  FROM page_returns
  WHERE wr_return_amt IS NOT NULL
  UNION
  SELECT 'demo' AS src, wr_return_amt AS return_amt
  FROM demo_returns
  WHERE wr_return_amt IS NOT NULL
) u
GROUP BY src
ORDER BY total_return_amt DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
