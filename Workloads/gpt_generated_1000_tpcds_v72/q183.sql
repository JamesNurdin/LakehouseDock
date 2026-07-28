WITH sr_combined AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        d1.d_year,
        i1.i_class,
        r1.r_reason_desc,
        s.s_store_name,
        d_closed1.d_year AS store_closed_year,
        d_closed2.d_year AS store_open_year
    FROM store_returns sr
    JOIN date_dim d1 ON sr.sr_returned_date_sk = d1.d_date_sk               -- join 1
    JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk                           -- join 2
    JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk                     -- join 3
    JOIN store s ON sr.sr_store_sk = s.s_store_sk                           -- join 4
    JOIN date_dim d_closed1 ON s.s_closed_date_sk = d_closed1.d_date_sk   -- join 5
    JOIN date_dim d_closed2 ON s.s_closed_date_sk = d_closed2.d_date_sk   -- join 6
)
SELECT
    dr.d_year,
    i2.i_class,
    r2.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(sr_combined.sr_net_loss) AS total_store_net_loss,
    (SUM(wr.wr_net_loss) + SUM(sr_combined.sr_net_loss)) AS total_combined_net_loss
FROM web_returns wr
JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk               -- join 7
JOIN item i2 ON wr.wr_item_sk = i2.i_item_sk                               -- join 8
JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk                         -- join 9
LEFT JOIN sr_combined ON wr.wr_item_sk = sr_combined.sr_item_sk
    AND wr.wr_returned_date_sk = sr_combined.sr_returned_date_sk
WHERE dr.d_year BETWEEN 1999 AND 2001
  AND i2.i_class IN ('accessories', 'scanners')
  AND EXISTS (
        SELECT 1
        FROM reason r3
        WHERE r3.r_reason_desc LIKE '%color%'
          AND r3.r_reason_sk = wr.wr_reason_sk
    )
GROUP BY dr.d_year, i2.i_class, r2.r_reason_desc
HAVING SUM(wr.wr_net_loss) > 1000
UNION ALL
SELECT
    d_closed1.d_year,
    i1.i_class,
    r1.r_reason_desc,
    COUNT(*) AS return_count,
    0.0 AS total_web_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    SUM(sr.sr_net_loss) AS total_combined_net_loss
FROM store_returns sr
JOIN date_dim d_closed1 ON sr.sr_returned_date_sk = d_closed1.d_date_sk   -- join 10
JOIN item i1 ON sr.sr_item_sk = i1.i_item_sk                                 -- join 11 (re‑used alias i1)
JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk                           -- join 12 (re‑used alias r1)
WHERE sr.sr_return_quantity > 1
  AND d_closed1.d_year = 2000
GROUP BY d_closed1.d_year, i1.i_class, r1.r_reason_desc
ORDER BY total_combined_net_loss DESC
LIMIT 100
