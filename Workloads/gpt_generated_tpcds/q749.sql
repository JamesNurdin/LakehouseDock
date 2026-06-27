WITH ss AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        SUM(s.ss_net_profit) AS total_profit,
        SUM(s.ss_quantity) AS total_quantity,
        COUNT(DISTINCT s.ss_ticket_number) AS order_count
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, p.p_promo_name
),
wr AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_net_loss) AS total_loss,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
inv AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    ss.d_year,
    ss.d_month_seq,
    ss.p_promo_name,
    ss.total_profit,
    ss.total_quantity,
    ss.order_count,
    COALESCE(wr.total_loss, 0) AS total_loss,
    COALESCE(wr.total_return_qty, 0) AS total_return_qty,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    ROW_NUMBER() OVER (PARTITION BY ss.d_year, ss.d_month_seq ORDER BY ss.total_profit DESC) AS profit_rank
FROM ss
LEFT JOIN wr ON ss.d_year = wr.d_year AND ss.d_month_seq = wr.d_month_seq
LEFT JOIN inv ON ss.d_year = inv.d_year AND ss.d_month_seq = inv.d_month_seq
ORDER BY ss.d_year, ss.d_month_seq, profit_rank
