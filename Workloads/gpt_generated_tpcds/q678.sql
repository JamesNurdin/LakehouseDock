WITH agg AS (
    SELECT
        s.s_store_name,
        ds.d_year,
        ds.d_month_seq AS month_seq,
        i.i_category,
        SUM(ss.ss_quantity) AS total_sold_quantity,
        SUM(ss.ss_net_paid) AS total_sold_amount,
        SUM(ss.ss_net_profit) AS total_sold_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr.sr_refunded_cash), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s
        ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim ds
        ON ds.d_date_sk = ss.ss_sold_date_sk
    JOIN item i
        ON i.i_item_sk = ss.ss_item_sk
    WHERE ds.d_year = 2002
    GROUP BY s.s_store_name, ds.d_year, ds.d_month_seq, i.i_category
),
ranked AS (
    SELECT
        a.*, 
        ROW_NUMBER() OVER (
            PARTITION BY a.s_store_name, a.d_year, a.month_seq 
            ORDER BY a.total_sold_profit - a.total_return_loss DESC
        ) AS rn
    FROM agg a
)
SELECT
    r.s_store_name,
    r.d_year,
    r.month_seq,
    r.i_category,
    r.total_sold_quantity,
    r.total_sold_amount,
    r.total_return_quantity,
    r.total_return_amount,
    (r.total_sold_profit - r.total_return_loss) AS net_profit_after_returns,
    CASE WHEN r.total_sold_quantity = 0 THEN 0
         ELSE (r.total_return_quantity * 100.0 / r.total_sold_quantity)
    END AS return_rate_percent,
    CASE WHEN r.total_sold_quantity = 0 THEN 0
         ELSE (r.total_discount_amount / r.total_sold_quantity)
    END AS avg_discount_per_item
FROM ranked r
WHERE r.rn = 1
ORDER BY r.s_store_name, r.d_year, r.month_seq
