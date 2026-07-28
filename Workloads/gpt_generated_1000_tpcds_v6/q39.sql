WITH grouped AS (
    SELECT
        d_wr.d_year,
        i.i_category,
        i.i_color,
        ca.ca_state,
        cd_refunded.cd_marital_status,
        r.r_reason_desc,
        COUNT(DISTINCT wr.wr_order_number) AS orders_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_quantity) AS avg_qty,
        MIN(d_wr.d_date) AS first_return_date,
        MAX(d_wr.d_date) AS last_return_date,
        CASE WHEN SUM(wr.wr_return_amt) > (
                SELECT AVG(wr2.wr_return_amt)
                FROM web_returns wr2
            ) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS amt_category
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d_wr.d_date_sk
    WHERE d_wr.d_year = 2001
      AND i.i_color IN ('royal', 'tan')
      AND ca.ca_state = 'CA'
      AND cd_refunded.cd_marital_status = 'M'
      AND r.r_reason_desc LIKE '%defective%'
    GROUP BY
        d_wr.d_year,
        i.i_category,
        i.i_color,
        ca.ca_state,
        cd_refunded.cd_marital_status,
        r.r_reason_desc
)
SELECT
    g.d_year,
    g.i_category,
    g.i_color,
    g.ca_state,
    g.cd_marital_status,
    g.r_reason_desc,
    g.orders_cnt,
    g.total_return_amt,
    g.avg_qty,
    g.first_return_date,
    g.last_return_date,
    g.amt_category,
    RANK() OVER (ORDER BY g.total_return_amt DESC) AS return_amount_rank
FROM grouped g
ORDER BY g.total_return_amt DESC
LIMIT 100
