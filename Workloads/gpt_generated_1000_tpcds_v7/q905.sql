WITH site_returns AS (
    SELECT
        ws.web_site_id,
        d.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002                     -- filter 1: specific fiscal year
      AND ws.web_suite_number = 'Suite 150'   -- filter 2: particular suite
      AND wr.wr_return_quantity > 1           -- filter 3: quantity threshold
    GROUP BY ws.web_site_id, d.d_year
)
SELECT
    d_year,
    AVG(total_net_loss) AS avg_total_net_loss,
    SUM(return_cnt) AS total_returns,
    COUNT(*) AS site_count
FROM site_returns
WHERE total_net_loss > 1000                     -- filter 4: meaningful loss amount
GROUP BY d_year
HAVING AVG(total_net_loss) > 500                -- filter 5: average loss threshold
ORDER BY avg_total_net_loss DESC
