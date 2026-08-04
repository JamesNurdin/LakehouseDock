/*
Goal: Identify product items that were returned both through the catalog and store channels for warranty‑related reasons in 2020, compare their average return amounts, enrich with average promotion cost, and combine this result with high‑value web returns. The query demonstrates INTERSECT, UNION ALL, TABLESAMPLE, scalar subqueries, GROUP BY/HAVING, and paging.
*/
WITH
  -- Sample a fraction of catalog returns and keep only warranty‑related rows for 2020
  cat AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      d.d_year
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
      AND d.d_year = 2020
  ),
  -- Store returns for the same criteria
  store AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_amt,
      d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
      AND d.d_year = 2020
  ),
  -- Web returns for the same criteria (used later in a separate branch)
  web AS (
    SELECT
      wr.wr_item_sk,
      wr.wr_return_amt,
      d.d_year
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%warranty%'
      AND d.d_year = 2020
  ),
  -- Items that appear in BOTH catalog and store returns (INTERSECT)
  intersect_items AS (
    SELECT cr_item_sk AS item_sk FROM cat
    INTERSECT
    SELECT sr_item_sk FROM store
  ),
  -- Aggregate information for intersected items
  intersect_query AS (
    SELECT
      i.item_sk,
      COUNT(*) AS total_returns,
      AVG(COALESCE(cr.cr_return_amount, sr.sr_return_amt)) AS avg_return_amount,
      (
        SELECT AVG(p.p_cost)
        FROM promotion p
        WHERE p.p_item_sk = i.item_sk
      ) AS avg_promo_cost
    FROM intersect_items i
    LEFT JOIN cat cr   ON i.item_sk = cr.cr_item_sk
    LEFT JOIN store sr ON i.item_sk = sr.sr_item_sk
    GROUP BY i.item_sk
    HAVING AVG(COALESCE(cr.cr_return_amount, sr.sr_return_amt)) > 20
  ),
  -- High‑value web return items (second branch of the UNION ALL)
  web_query AS (
    SELECT
      wr.wr_item_sk AS item_sk,
      COUNT(*) AS total_returns,
      AVG(wr.wr_return_amt) AS avg_return_amount,
      (
        SELECT AVG(p.p_cost)
        FROM promotion p
        WHERE p.p_item_sk = wr.wr_item_sk
      ) AS avg_promo_cost
    FROM web wr
    GROUP BY wr.wr_item_sk
    HAVING AVG(wr.wr_return_amt) > 25
  )
SELECT *
FROM intersect_query
UNION ALL
SELECT *
FROM web_query
ORDER BY total_returns DESC, item_sk
OFFSET 20
LIMIT 100
