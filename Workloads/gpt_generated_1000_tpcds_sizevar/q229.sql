WITH inv_agg AS (
    SELECT
        inv_date_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY inv_date_sk, inv_warehouse_sk
),
base1 AS (
    SELECT
        d_ret.d_year AS return_year,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(i.total_qty) AS total_qty,
        COUNT(DISTINCT wr.wr_order_number) AS order_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_address ca_ref
        ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inv_agg i
        ON wr.wr_returned_date_sk = i.inv_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_ret.d_date_sk
    JOIN date_dim d_open
        ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY d_ret.d_year, r.r_reason_desc
),
base2 AS (
    SELECT
        d_close.d_year AS close_year,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) * 0.9 AS total_return_amt_adj,
        SUM(i.total_qty) AS total_qty,
        COUNT(DISTINCT wr.wr_order_number) AS order_cnt
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN inv_agg i
        ON wr.wr_returned_date_sk = i.inv_date_sk
    JOIN web_site ws
        ON ws.web_close_date_sk = d_ret.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_close.d_year = 2001
    GROUP BY d_close.d_year, r.r_reason_desc
),
union_set AS (
    SELECT
        return_year AS yr,
        r_reason_desc,
        total_return_amt,
        total_qty,
        order_cnt
    FROM base1
    UNION
    SELECT
        close_year AS yr,
        r_reason_desc,
        total_return_amt_adj,
        total_qty,
        order_cnt
    FROM base2
),
exclude_set AS (
    SELECT
        yr,
        r_reason_desc,
        total_return_amt,
        total_qty,
        order_cnt
    FROM union_set
    WHERE total_return_amt > 10000
),
final_set AS (
    SELECT *
    FROM union_set
    EXCEPT
    SELECT *
    FROM exclude_set
)
SELECT
    fs.yr,
    fs.r_reason_desc,
    fs.total_return_amt,
    fs.total_qty,
    fs.order_cnt,
    d_extra.d_month_seq
FROM final_set fs
FULL OUTER JOIN (
    SELECT d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
) d_extra
ON fs.yr = d_extra.d_year
ORDER BY fs.yr DESC
LIMIT 100
