WITH agg AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        i.i_manufact,
        i.i_category,
        s.s_state,
        s.s_city,
        t.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2020
      AND i.i_category = 'Electronics'
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        i.i_manufact,
        i.i_category,
        s.s_state,
        s.s_city,
        t.t_hour
)
SELECT
    agg.d_year,
    agg.d_quarter_name,
    agg.i_manufact,
    agg.i_category,
    agg.s_state,
    agg.s_city,
    agg.t_hour,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.return_cnt,
    agg.avg_return_qty,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY agg.total_return_amount DESC) AS rn_yearly
FROM agg
WHERE agg.total_return_amount > 1000
ORDER BY agg.total_net_loss DESC
LIMIT 100
