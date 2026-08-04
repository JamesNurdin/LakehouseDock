WITH
  -- Small set of years (2020‑2022) to build a grid
  years AS (
    SELECT DISTINCT d_year
    FROM date_dim
    WHERE d_year BETWEEN 2020 AND 2022
  ),

  -- Small set of reasons (first 10 rows) to keep the cross‑join lightweight
  reasons AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    ORDER BY r_reason_sk
    LIMIT 10
  ),

  -- Net loss per year / reason from store_returns
  agg AS (
    SELECT d.d_year,
           r.r_reason_desc,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY d.d_year, r.r_reason_desc
  ),

  -- Complete year × reason matrix (cartesian product)
  full_grid AS (
    SELECT y.d_year,
           r.r_reason_desc
    FROM years y
    CROSS JOIN reasons r
  ),

  -- Merge the matrix with the actual aggregates, fill missing with 0
  merged AS (
    SELECT fg.d_year,
           fg.r_reason_desc,
           COALESCE(a.total_net_loss, 0) AS total_net_loss,
           -- Flag reasons containing words like "damage" or "defect"
           CASE WHEN regexp_like(fg.r_reason_desc, '(?i)damage|defect') THEN 1 ELSE 0 END AS is_problem_reason,
           concat('Reason: ', fg.r_reason_desc) AS reason_label,
           -- Extract the first word of the reason description
           regexp_extract(fg.r_reason_desc, '^([A-Za-z]+)', 1) AS first_word
    FROM full_grid fg
    LEFT JOIN agg a
      ON fg.d_year = a.d_year
     AND fg.r_reason_desc = a.r_reason_desc
  ),

  -- Customers that appear in web_sales but never in store_returns
  customers_web AS (
    SELECT DISTINCT ws_bill_customer_sk AS cust_sk
    FROM web_sales
  ),
  customers_store AS (
    SELECT DISTINCT sr_customer_sk AS cust_sk
    FROM store_returns
  ),
  only_web_customers AS (
    SELECT cust_sk FROM customers_web
    EXCEPT
    SELECT cust_sk FROM customers_store
  )

SELECT
  -- Year and reason (may be NULL when roll‑up produces subtotals)
  d_year,
  r_reason_desc,
  SUM(total_net_loss) AS total_net_loss,
  -- Human‑readable label for the year level (null => "All Years")
  CASE WHEN d_year IS NULL THEN 'All Years'
       ELSE concat('Year ', CAST(d_year AS VARCHAR))
  END AS year_label,
  -- Reason category based on the regex flag
  CASE WHEN is_problem_reason = 1 THEN 'Problem'
       ELSE 'Other'
  END AS reason_category,
  -- Shortened concatenated label (string manipulation example)
  substring(reason_label, 1, 30) AS short_reason_label,
  -- First word of the reason description (regex extract example)
  first_word,
  -- Global row number ordered by the aggregated loss (no downstream filter)
  ROW_NUMBER() OVER (ORDER BY SUM(total_net_loss) DESC) AS rn,
  -- Grand count of customers that purchased on the web but never returned in‑store
  (SELECT COUNT(*) FROM only_web_customers) AS web_only_customer_cnt
FROM merged
GROUP BY ROLLUP (d_year, r_reason_desc, is_problem_reason, reason_label, first_word)
ORDER BY total_net_loss DESC, d_year, r_reason_desc
LIMIT 100
