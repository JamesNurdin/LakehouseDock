WITH
  store_agg AS (
    SELECT
      sr.sr_store_sk,
      td.t_hour,
      r.r_reason_desc,
      SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE td.t_am_pm = 'PM'
      AND r.r_reason_desc LIKE '%price%'
      AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = sr.sr_store_sk
          AND r2.r_reason_desc LIKE 'unauthoized purchase%'
      )
    GROUP BY ROLLUP (sr.sr_store_sk, td.t_hour, r.r_reason_desc)
    HAVING SUM(sr.sr_net_loss) > 1000
  ),
  web_agg AS (
    SELECT
      wr.wr_web_page_sk,
      td.t_hour,
      r.r_reason_desc,
      SUM(wr.wr_net_loss) AS web_net_loss
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE td.t_am_pm = 'AM'
      AND r.r_reason_desc LIKE '%warranty%'
    GROUP BY ROLLUP (wr.wr_web_page_sk, td.t_hour, r.r_reason_desc)
    HAVING SUM(wr.wr_net_loss) > 500
  ),
  combined AS (
    SELECT
      sr.sr_store_sk AS entity_id,
      sr.t_hour,
      sr.r_reason_desc,
      sr.store_net_loss AS net_loss,
      'store' AS source
    FROM store_agg sr
    UNION ALL
    SELECT
      wr.wr_web_page_sk AS entity_id,
      wr.t_hour,
      wr.r_reason_desc,
      wr.web_net_loss AS net_loss,
      'web' AS source
    FROM web_agg wr
  ),
  store_keys AS (
    SELECT sr_store_sk AS entity_id FROM store_returns
  ),
  web_keys AS (
    SELECT wr_web_page_sk AS entity_id FROM web_returns
  ),
  web_not_in_store AS (
    SELECT entity_id FROM web_keys
    EXCEPT
    SELECT entity_id FROM store_keys
  )
SELECT
  c.entity_id,
  c.t_hour,
  c.r_reason_desc,
  c.net_loss,
  c.source,
  ROW_NUMBER() OVER (ORDER BY c.net_loss DESC) AS rn_global,
  SUM(c.net_loss) OVER (PARTITION BY c.source ORDER BY c.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
  lm.max_minute
FROM combined c
CROSS JOIN LATERAL (
  SELECT MAX(t_minute) AS max_minute
  FROM time_dim td2
  WHERE td2.t_hour = c.t_hour
) lm
WHERE c.entity_id NOT IN (SELECT entity_id FROM web_not_in_store)
ORDER BY c.net_loss DESC, rn_global
LIMIT 100
