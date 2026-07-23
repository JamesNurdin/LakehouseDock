WITH combined_returns AS (
    SELECT
        'Catalog' AS return_source,
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt,
        t.t_hour AS hour_of_day
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
    UNION ALL
    SELECT
        'Web' AS return_source,
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        wr.wr_return_quantity AS return_qty,
        wr.wr_return_amt AS return_amt,
        t.t_hour AS hour_of_day
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
      AND r.r_reason_desc LIKE '%Damaged%'
      AND cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
)
SELECT
    return_source,
    i_item_id,
    i_item_desc,
    r_reason_desc,
    hour_of_day,
    SUM(return_qty) AS total_return_qty,
    SUM(return_amt) AS total_return_amt,
    AVG(return_amt) AS avg_return_amt
FROM combined_returns
GROUP BY
    return_source,
    i_item_id,
    i_item_desc,
    r_reason_desc,
    hour_of_day
ORDER BY total_return_amt DESC
LIMIT 100
