WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type,
        t.t_hour,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_current_month = 'Y'
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type, t.t_hour
),
ranked AS (
    SELECT
        b.*, 
        RANK() OVER (PARTITION BY b.d_year, b.d_month_seq ORDER BY b.total_net_loss DESC) AS net_loss_rank,
        (SELECT SUM(i.inv_quantity_on_hand)
         FROM inventory i
         JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
         WHERE d2.d_year = b.d_year
           AND d2.d_month_seq = b.d_month_seq) AS total_inventory_qty
    FROM base b
)
SELECT
    r.d_year,
    r.d_month_seq,
    r.wp_type,
    r.t_hour,
    r.return_cnt,
    r.total_net_loss,
    r.total_return_amt_inc_tax,
    r.net_loss_rank,
    r.total_inventory_qty,
    (r.total_net_loss / NULLIF(r.total_inventory_qty, 0)) AS loss_per_inventory
FROM ranked r
WHERE r.net_loss_rank <= 5
ORDER BY r.d_year DESC, r.d_month_seq DESC, r.net_loss_rank
LIMIT 200
