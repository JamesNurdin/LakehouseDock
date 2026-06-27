WITH sales_agg AS (
    SELECT
        d_sold.d_year,
        d_sold.d_month_seq,
        i.i_category,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE d_sold.d_year = 1998
    GROUP BY d_sold.d_year, d_sold.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        i.i_category,
        SUM(cr.cr_refunded_cash) AS total_refunded_cash,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE d_ret.d_year = 1998
    GROUP BY d_ret.d_year, d_ret.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_net_paid,
    s.total_net_profit,
    COALESCE(r.total_refunded_cash, 0) AS total_refunded_cash,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
    (s.total_net_paid - COALESCE(r.total_refunded_cash, 0)) AS net_paid_after_returns,
    SUM(s.total_net_profit - COALESCE(r.total_net_loss, 0))
        OVER (PARTITION BY s.i_category ORDER BY s.d_year, s.d_month_seq
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
ORDER BY s.d_year DESC, s.d_month_seq DESC, s.i_category
