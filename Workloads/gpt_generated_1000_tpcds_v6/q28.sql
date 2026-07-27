WITH returning_addr AS (
    SELECT
        wr.wr_returning_addr_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_refunded_cash,
        wr.wr_return_ship_cost,
        ca.ca_county,
        ca.ca_address_id,
        ca.ca_suite_number
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_address_id, '^A{8}I')
      AND ca.ca_suite_number LIKE 'Suite %'
),
agg AS (
    SELECT
        r.ca_county,
        COUNT(*) AS returns_cnt,
        SUM(r.wr_return_amt) AS total_return_amt,
        AVG(r.wr_return_amt) AS avg_return_amt,
        SUM(CASE WHEN r.wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns) THEN 1 ELSE 0 END) AS high_return_cnt
    FROM returning_addr r
    WHERE EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN customer_address ca2
          ON wr2.wr_refunded_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_county = r.ca_county
          AND wr2.wr_refunded_cash > 100
    )
    GROUP BY r.ca_county
)
SELECT
    a.ca_county,
    a.returns_cnt,
    a.total_return_amt,
    a.avg_return_amt,
    a.high_return_cnt,
    RANK() OVER (ORDER BY a.total_return_amt DESC) AS county_rank
FROM agg a
ORDER BY a.total_return_amt DESC
LIMIT 100
