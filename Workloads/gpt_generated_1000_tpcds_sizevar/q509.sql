/*
  Goal: Combine sales from stores and the web for the year 2001, aggregate by year and item category with subtotals (ROLLUP), merge with catalog return amounts using a full outer join, filter out years that appear in an older‑year subquery (anti‑semi‑join), de‑duplicate the combined sales using UNION, and paginate the ordered result.
*/
WITH
  -- Aggregate store sales by year and category with rollup subtotals
  store_agg AS (
    SELECT
      d.d_year               AS year,
      i.i_category           AS category,
      SUM(ss.ss_net_paid)   AS total_sales
    FROM store_sales ss
    JOIN date_dim d   ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i       ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (d.d_year, i.i_category)
  ),

  -- Aggregate web sales by year and category with rollup subtotals
  web_agg AS (
    SELECT
      d.d_year               AS year,
      i.i_category           AS category,
      SUM(ws.ws_net_paid)   AS total_sales
    FROM web_sales ws
    JOIN date_dim d   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i       ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (d.d_year, i.i_category)
  ),

  -- Union the two sales sources (deduplication via UNION)
  union_sales AS (
    SELECT year, category, total_sales FROM store_agg
    UNION
    SELECT year, category, total_sales FROM web_agg
  ),

  -- Aggregate catalog returns by year and category with rollup subtotals
  returns_agg AS (
    SELECT
      d.d_year                     AS year,
      i.i_category                 AS category,
      SUM(cr.cr_return_amount)    AS total_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i     ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY ROLLUP (d.d_year, i.i_category)
  )

SELECT
  us.year,
  us.category,
  us.total_sales,
  ra.total_returns
FROM union_sales us
FULL OUTER JOIN returns_agg ra
  ON us.year = ra.year
 AND us.category = ra.category
-- Anti‑semi‑join: exclude years that appear in a historic‑year subquery
WHERE us.year NOT IN (
        SELECT d_sub.d_year
        FROM date_dim d_sub
        WHERE d_sub.d_year < 2000
      )
ORDER BY us.year DESC NULLS LAST, us.category
OFFSET 0 ROWS FETCH FIRST 100 ROWS ONLY
