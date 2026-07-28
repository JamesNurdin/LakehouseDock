WITH returns_agg AS (
    SELECT
        d.d_year,
        ca.ca_zip,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ca.ca_state = 'CA'
      AND sr.sr_return_amt > 20
    GROUP BY d.d_year, ca.ca_zip
)
SELECT
    r.d_year,
    r.ca_zip,
    r.return_cnt,
    r.total_return_amt,
    r.total_net_loss,
    AVG(r.total_return_amt) OVER (PARTITION BY r.d_year) AS avg_return_amt_by_year,
    RANK() OVER (PARTITION BY r.d_year ORDER BY r.total_return_amt DESC) AS return_amt_rank,
    CASE
        WHEN r.total_net_loss > (
            SELECT AVG(total_net_loss)
            FROM returns_agg
            WHERE d_year = r.d_year
        ) THEN 'High'
        ELSE 'Low'
    END AS net_loss_category
FROM returns_agg r
WHERE r.return_cnt >= (
    SELECT MIN(return_cnt)
    FROM returns_agg
    WHERE d_year = r.d_year
)
ORDER BY r.d_year, return_amt_rank
