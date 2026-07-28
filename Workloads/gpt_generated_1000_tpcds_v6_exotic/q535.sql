WITH
  agg1 AS (
    SELECT
      r.r_reason_desc,
      d.d_year,
      SUM(wr.wr_net_loss) AS total_net_loss,
      COUNT(*) AS cnt_returns,
      AVG(wr.wr_reversed_charge) AS avg_rev_charge,
      SUM(CASE WHEN wr.wr_net_loss > 100 THEN 1 ELSE 0 END) AS high_loss_cnt
    FROM web_returns AS wr
    JOIN date_dim AS d
      ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason AS r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page AS wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                 -- filter 1: year range
      AND wp.wp_char_count BETWEEN 1000 AND 5000        -- filter 2: page size range
      AND r.r_reason_desc LIKE '%working%'             -- filter 3: reason text
      AND EXISTS (
            SELECT 1
            FROM web_page wp2
            WHERE wp2.wp_web_page_sk = wp.wp_web_page_sk
              AND wp2.wp_link_count > 30               -- sub‑query predicate
          )
    GROUP BY r.r_reason_desc, d.d_year
  ),
  agg2 AS (
    SELECT
      d_year,
      SUM(total_net_loss) AS year_total_loss,
      SUM(cnt_returns) AS year_cnt_returns,
      AVG(avg_rev_charge) AS year_avg_rev_charge
    FROM agg1
    GROUP BY d_year
    HAVING SUM(total_net_loss) > 10000                -- HAVING on aggregated groups
  )
SELECT
  a.r_reason_desc,
  a.d_year,
  a.total_net_loss,
  a.cnt_returns,
  a.avg_rev_charge,
  a.high_loss_cnt,
  a.loss_rank,
  a.year_total_net_loss,
  b.year_total_loss,
  b.year_cnt_returns,
  b.year_avg_rev_charge
FROM (
  SELECT
    r_reason_desc,
    d_year,
    total_net_loss,
    cnt_returns,
    avg_rev_charge,
    high_loss_cnt,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank,
    SUM(total_net_loss) OVER (PARTITION BY d_year) AS year_total_net_loss
  FROM agg1
) a
JOIN agg2 b ON a.d_year = b.d_year
WHERE a.high_loss_cnt > 0
ORDER BY a.d_year DESC, a.total_net_loss DESC
LIMIT 100
