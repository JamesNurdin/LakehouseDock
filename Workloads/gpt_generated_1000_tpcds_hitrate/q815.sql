WITH
  promo_sales AS (
    SELECT DISTINCT cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
  ),
  promo_clearance AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, 'Clearance')
  ),
  eligible_promos AS (
    SELECT cs_promo_sk FROM promo_sales
    EXCEPT
    SELECT p_promo_sk FROM promo_clearance
  ),
  sales_data AS (
    SELECT
      p.p_promo_name AS promo_name,
      NULL AS reason_desc,
      SUM(cs.cs_net_paid) AS sales_amount,
      0.0 AS returns_amount,
      CONCAT(p.p_promo_name, '_', lc.promo_code) AS full_promo
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN eligible_promos ep ON cs.cs_promo_sk = ep.cs_promo_sk
    CROSS JOIN LATERAL (
      SELECT regexp_extract(p.p_promo_id, '([A-Z]+)$') AS promo_code
    ) AS lc
    WHERE d.d_year = 2002
      AND regexp_like(p.p_promo_name, 'Discount')
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY p.p_promo_name, p.p_promo_id, lc.promo_code
  ),
  returns_data AS (
    SELECT
      NULL AS promo_name,
      r.r_reason_desc AS reason_desc,
      0.0 AS sales_amount,
      SUM(wr.wr_return_amt) AS returns_amount,
      NULL AS full_promo
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY r.r_reason_desc
  ),
  combined AS (
    SELECT * FROM sales_data
    UNION ALL
    SELECT * FROM returns_data
  ),
  aggregated AS (
    SELECT
      promo_name,
      reason_desc,
      SUM(sales_amount) AS total_sales,
      SUM(returns_amount) AS total_returns,
      MAX(full_promo) AS full_promo
    FROM combined
    GROUP BY ROLLUP (promo_name, reason_desc)
  ),
  ranked AS (
    SELECT
      promo_name,
      reason_desc,
      total_sales,
      total_returns,
      full_promo,
      ROW_NUMBER() OVER (PARTITION BY promo_name ORDER BY total_sales DESC) AS sales_rank,
      (SELECT max(d_year) FROM date_dim) AS max_year
    FROM aggregated
  )
SELECT
  promo_name,
  reason_desc,
  total_sales,
  total_returns,
  full_promo,
  sales_rank,
  max_year
FROM ranked
ORDER BY promo_name NULLS LAST, reason_desc NULLS LAST
