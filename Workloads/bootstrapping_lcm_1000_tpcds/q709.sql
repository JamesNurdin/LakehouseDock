WITH daily_agg AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_state,
        ws.web_country,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amount,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT cr.cr_item_sk) AS distinct_items
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_state,
        ws.web_country
)
SELECT
    d_date,
    d_year,
    d_month_seq,
    sm_type,
    s_state,
    web_country,
    total_qty,
    total_amount,
    avg_net_loss,
    distinct_items,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_amount DESC) AS rank_by_amount,
    SUM(total_amount) OVER (
        PARTITION BY d_year
        ORDER BY d_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_amount_year
FROM daily_agg
ORDER BY d_date
LIMIT 100
