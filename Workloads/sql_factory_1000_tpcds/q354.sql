WITH returns_by_shift AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        td.t_shift,
        SUM(cr.cr_net_loss) AS shift_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY cr.cr_returned_date_sk, td.t_shift
),
sales_by_shift AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        td.t_shift,
        SUM(ws.ws_net_paid) AS shift_sales,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY ws.ws_sold_date_sk, td.t_shift
)
SELECT
    r.date_sk,
    r.t_shift,
    r.shift_loss,
    s.shift_sales,
    r.shift_loss - s.shift_sales AS net_balance,
    SUM(r.shift_loss) OVER (PARTITION BY r.t_shift ORDER BY r.date_sk) AS cumulative_loss_by_shift,
    SUM(s.shift_sales) OVER (PARTITION BY r.t_shift ORDER BY r.date_sk) AS cumulative_sales_by_shift,
    CASE
        WHEN r.shift_loss > s.shift_sales THEN 'Loss Shift'
        ELSE 'Profit Shift'
    END AS shift_status,
    DENSE_RANK() OVER (ORDER BY (r.shift_loss - s.shift_sales) DESC) AS net_balance_rank
FROM returns_by_shift r
LEFT JOIN sales_by_shift s
    ON r.date_sk = s.date_sk
    AND r.t_shift = s.t_shift
ORDER BY r.date_sk, r.t_shift
