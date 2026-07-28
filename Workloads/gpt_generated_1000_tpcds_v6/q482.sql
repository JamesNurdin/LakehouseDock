/*
Goal: Compare total net loss from store returns and web returns for the year 2001, excluding returns whose reason mentions "color" and focusing on US customers for store returns. The query uses UNION ALL to combine the two sources, includes scalar subqueries, an anti‑join via NOT EXISTS, and produces subtotals with ROLLUP. Results are limited to the first 100 rows.
*/
WITH
  /* Maximum year in the date dimension – used as a scalar subquery value */
  max_year AS (
    SELECT max(d_year) AS yr FROM date_dim
  ),

  /* Store return aggregation */
  store_ret AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      SUM(sr.sr_net_loss) AS total_loss,
      'store' AS src,
      (SELECT yr FROM max_year) AS max_year
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    /* Restrict to the year 2001 */
    WHERE d.d_year = 2001
      /* Exclude reasons that mention "color" (anti‑join) */
      AND NOT EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_sk = sr.sr_reason_sk
              AND r2.r_reason_desc LIKE '%color%'
          )
      /* Keep only returns from US addresses */
      AND EXISTS (
            SELECT 1
            FROM customer_address ca
            WHERE ca.ca_address_sk = sr.sr_addr_sk
              AND ca.ca_country = 'United States'
          )
    GROUP BY GROUPING SETS ((r.r_reason_desc), ())
  ),

  /* Web return aggregation */
  web_ret AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      SUM(wr.wr_net_loss) AS total_loss,
      'web' AS src,
      (SELECT yr FROM max_year) AS max_year
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND NOT EXISTS (
            SELECT 1
            FROM reason r2
            WHERE r2.r_reason_sk = wr.wr_reason_sk
              AND r2.r_reason_desc LIKE '%color%'
          )
    GROUP BY GROUPING SETS ((r.r_reason_desc), ())
  )

SELECT
  src,
  COALESCE(reason_desc, 'ALL') AS reason_desc,
  SUM(total_loss) AS loss_amount,
  MAX(max_year) AS max_year
FROM (
  SELECT src, reason_desc, total_loss, max_year FROM store_ret
  UNION ALL
  SELECT src, reason_desc, total_loss, max_year FROM web_ret
) u
GROUP BY ROLLUP (src, reason_desc)
ORDER BY src, reason_desc
LIMIT 100
