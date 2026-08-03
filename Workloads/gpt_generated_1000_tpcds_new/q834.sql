WITH scalar_max AS (
    SELECT MAX(r_reason_sk) AS max_sk
    FROM reason
),

returns_filtered AS (
    SELECT *
    FROM web_returns
    WHERE wr_return_quantity > 1
      AND wr_return_amt > 10
      AND wr_returning_addr_sk IN (1976016, 4429603)
      AND wr_refunded_addr_sk NOT IN (2453001)
),

returns_with_lateral AS (
    SELECT wr.*,
           lt.ten_percent
    FROM returns_filtered AS wr
    CROSS JOIN LATERAL (
        SELECT wr.wr_return_amt * 0.1 AS ten_percent
    ) AS lt
),

unioned AS (
    SELECT
        r.r_reason_desc,
        wr.wr_returning_addr_sk,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN wr.wr_return_amt > 1000 THEN 1 ELSE 0 END) AS high_return_cnt
    FROM returns_with_lateral wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_sk = (SELECT max_sk FROM scalar_max)
    GROUP BY r.r_reason_desc, wr.wr_returning_addr_sk
    HAVING COUNT(*) > 5

    UNION

    SELECT
        r.r_reason_desc,
        wr.wr_returning_addr_sk,
        SUM(wr.wr_return_amt) AS sum_return_amt,
        COUNT(*) AS cnt_returns,
        SUM(CASE WHEN wr.wr_return_amt > 500 THEN 1 ELSE 0 END) AS high_return_cnt
    FROM returns_with_lateral wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%gift%'
    GROUP BY r.r_reason_desc, wr.wr_returning_addr_sk
    HAVING COUNT(*) > 3
),

final_set AS (
    SELECT *
    FROM unioned
    EXCEPT
    SELECT r.r_reason_desc, NULL, NULL, NULL, NULL
    FROM reason r
    WHERE r.r_reason_id = 'AAAAAAAABAAAAAAA'
)

SELECT *
FROM final_set
LIMIT 100
