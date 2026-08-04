WITH
  refunded AS (
    SELECT
      cr.cr_refunded_customer_sk AS cust_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_call_center_sk,
      cc.cc_company_name,
      cc.cc_mkt_class,
      lc.market_word
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN LATERAL (
      SELECT regexp_extract(cc.cc_mkt_class, '(\\w+)', 1) AS market_word
    ) lc ON true
    WHERE regexp_like(cc.cc_mkt_class, '.*basic.*')
      AND cc.cc_company_name LIKE 'cally%'
  ),
  returning AS (
    SELECT
      cr.cr_returning_customer_sk AS cust_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_call_center_sk,
      cc.cc_company_name,
      cc.cc_mkt_class,
      lc.market_word
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN LATERAL (
      SELECT regexp_extract(cc.cc_mkt_class, '(\\w+)', 1) AS market_word
    ) lc ON true
    WHERE cc.cc_company_name LIKE 'pr%'
      AND regexp_like(cc.cc_mkt_class, '.*Major.*')
  ),
  full_data AS (
    SELECT
      COALESCE(r.cust_sk, f.cust_sk) AS cust_sk,
      COALESCE(r.cc_company_name, f.cc_company_name) AS company_name,
      COALESCE(r.market_word, f.market_word) AS market_word,
      SUM(COALESCE(r.cr_return_amount, 0) + COALESCE(f.cr_return_amount, 0)) AS total_return_amount,
      SUM(COALESCE(r.cr_return_quantity, 0) + COALESCE(f.cr_return_quantity, 0)) AS total_qty,
      CASE
        WHEN SUM(COALESCE(r.cr_return_amount, 0) + COALESCE(f.cr_return_amount, 0)) > 10000 THEN 'High'
        ELSE 'Low'
      END AS return_level
    FROM refunded f
    FULL OUTER JOIN returning r
      ON f.cr_call_center_sk = r.cr_call_center_sk
     AND f.cc_company_name = r.cc_company_name
    GROUP BY
      COALESCE(r.cust_sk, f.cust_sk),
      COALESCE(r.cc_company_name, f.cc_company_name),
      COALESCE(r.market_word, f.market_word)
  )
SELECT
  cust_sk,
  company_name,
  market_word,
  total_return_amount,
  total_qty,
  return_level
FROM (
  SELECT
    cust_sk,
    company_name,
    market_word,
    total_return_amount,
    total_qty,
    return_level
  FROM full_data
  WHERE market_word LIKE 'Only%'

  UNION DISTINCT

  SELECT
    cust_sk,
    company_name,
    market_word,
    total_return_amount * 0.9 AS total_return_amount,
    total_qty,
    CASE WHEN total_return_amount * 0.9 > 10000 THEN 'High' ELSE 'Low' END AS return_level
  FROM full_data
  WHERE return_level = 'Low'
) final
LIMIT 100
