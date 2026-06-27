WITH store_ret AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        r.r_reason_desc AS reason,
        i.i_category AS category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY 1, 2, 3
),
web_ret AS (
    SELECT
        date_trunc('month', d.d_date) AS month,
        r.r_reason_desc AS reason,
        i.i_category AS category,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY 1, 2, 3
),
combined AS (
    SELECT month, reason, category,
        total_net_loss,
        total_return_qty,
        total_refunded_cash,
        return_count
    FROM store_ret
    UNION ALL
    SELECT month, reason, category,
        total_net_loss,
        total_return_qty,
        total_refunded_cash,
        return_count
    FROM web_ret
)
SELECT
    month,
    reason,
    category,
    SUM(total_net_loss) AS net_loss,
    SUM(total_return_qty) AS return_qty,
    SUM(total_refunded_cash) AS refunded_cash,
    SUM(return_count) AS returns
FROM combined
GROUP BY month, reason, category
ORDER BY month, net_loss DESC
