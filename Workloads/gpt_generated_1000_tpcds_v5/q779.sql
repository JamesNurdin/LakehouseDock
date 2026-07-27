WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_refunded_customer_sk,
        wr.wr_returning_customer_sk,
        d_ret.d_year,
        r.r_reason_desc,
        c_ref.c_customer_id AS refunded_customer_id,
        c_ret.c_customer_id AS returning_customer_id,
        c_ret.c_birth_month,
        cp.cp_department,
        cp.cp_catalog_page_id,
        ws.web_name,
        ws.web_country
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_ref
        ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret
        ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d_ret.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND r.r_reason_desc LIKE '%working%'
      AND cp.cp_department = 'Electronics'
      AND ws.web_country = 'United States'
      AND c_ret.c_birth_month = 7
      AND wr.wr_return_amt > 100.00
),
agg AS (
    SELECT
        d_year,
        web_name,
        r_reason_desc,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_quantity,
        SUM(wr_net_loss) AS total_net_loss
    FROM base
    GROUP BY GROUPING SETS (
        (d_year, web_name, r_reason_desc),
        (d_year, web_name),
        (d_year),
        ()
    )
)
SELECT
    d_year,
    web_name,
    r_reason_desc,
    total_return_amt,
    total_quantity,
    CASE WHEN total_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS net_loss_flag,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_by_amt
FROM agg
ORDER BY d_year, web_name, r_reason_desc
LIMIT 100
