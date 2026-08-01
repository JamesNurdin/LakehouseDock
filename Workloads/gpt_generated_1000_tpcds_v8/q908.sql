WITH catalog_part AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_reason_sk,
        cr.cr_refunded_cash,
        cr.cr_net_loss,
        d.d_year,
        d.d_date,
        t.t_hour,
        r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                           -- filter 1
      AND t.t_hour BETWEEN 9 AND 17                -- filter 2
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'      -- filter 3
      AND cr.cr_refunded_cash > 100.00            -- filter 4
      AND cr.cr_return_quantity >= 2              -- filter 5
),

web_part AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_returned_time_sk,
        wr.wr_reason_sk,
        wr.wr_refunded_cash,
        wr.wr_net_loss,
        d.d_year,
        d.d_date,
        t.t_hour,
        r.r_reason_desc
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001                           -- filter 1
      AND t.t_hour BETWEEN 9 AND 17                -- filter 2
      AND r.r_reason_id = 'AAAAAAAAPAAAAAAA'      -- filter 3
      AND wr.wr_refunded_cash > 100.00            -- filter 4
      AND wr.wr_return_quantity >= 2              -- filter 5
),

union_all_returns AS (
    SELECT
        'catalog' AS source,
        cr_returned_date_sk AS date_sk,
        cr_returned_time_sk AS time_sk,
        cr_reason_sk AS reason_sk,
        cr_refunded_cash AS refunded_cash,
        cr_net_loss AS net_loss,
        d_year,
        d_date,
        t_hour,
        r_reason_desc
    FROM catalog_part
    UNION DISTINCT
    SELECT
        'web' AS source,
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_reason_sk,
        wr_refunded_cash,
        wr_net_loss,
        d_year,
        d_date,
        t_hour,
        r_reason_desc
    FROM web_part
),

filtered_excluding AS (
    SELECT *
    FROM union_all_returns u
    EXCEPT
    SELECT *
    FROM union_all_returns u2
    WHERE u2.refunded_cash > 5000.00
)

SELECT
    f.source,
    f.d_year,
    f.r_reason_desc,
    SUM(f.refunded_cash) AS total_refunded_cash,
    AVG(f.net_loss) AS avg_net_loss,
    COUNT(*) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY f.d_year ORDER BY SUM(f.refunded_cash) DESC) AS rn,
    (
        SELECT SUM(cr.cr_refunded_cash)
        FROM catalog_returns cr
        WHERE cr.cr_returned_date_sk = f.date_sk
    ) AS catalog_cash_same_date
FROM filtered_excluding f
GROUP BY f.source, f.d_year, f.r_reason_desc, f.date_sk
HAVING SUM(f.refunded_cash) > (
    SELECT AVG(cr2.cr_return_quantity)
    FROM catalog_returns cr2
    WHERE cr2.cr_returned_date_sk = f.date_sk
)
ORDER BY total_refunded_cash DESC
OFFSET 10 LIMIT 100
