WITH returns_by_date AS (
    SELECT
        d.d_year,
        d.d_holiday,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_net_loss) AS net_loss,
        SUM(wr.wr_return_quantity) AS total_qty,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1900 AND 1904
    GROUP BY d.d_year, d.d_holiday
),
stores_closed_by_year AS (
    SELECT
        d.d_year,
        COUNT(DISTINCT s.s_store_id) AS stores_closed_cnt
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1900 AND 1904
    GROUP BY d.d_year
)
SELECT
    r.d_year,
    r.d_holiday,
    r.return_cnt,
    r.net_loss,
    r.total_qty,
    r.total_return_amt,
    COALESCE(s.stores_closed_cnt, 0) AS stores_closed_cnt,
    ROUND(100.0 * r.net_loss / NULLIF(SUM(r.net_loss) OVER (PARTITION BY r.d_year), 0), 2) AS pct_of_year_net_loss,
    SUM(r.net_loss) OVER (PARTITION BY r.d_year ORDER BY r.d_holiday ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_net_loss
FROM returns_by_date r
LEFT JOIN stores_closed_by_year s
    ON r.d_year = s.d_year
ORDER BY r.d_year ASC, r.d_holiday DESC
