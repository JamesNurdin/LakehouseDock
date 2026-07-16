WITH agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_city,
        ws.web_name,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_quantity) AS total_quantity,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        SUM(cr.cr_fee) AS total_fee,
        ROUND(SUM(cr.cr_return_tax), 2) AS total_tax,
        SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND sm.sm_carrier = 'UPS'
      AND s.s_state = 'CA'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_city,
        ws.web_name
    HAVING SUM(cr.cr_net_loss) > 0
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.sm_type,
    agg.s_city,
    agg.web_name,
    agg.total_returns,
    agg.total_quantity,
    agg.total_net_loss,
    agg.avg_return_amount,
    agg.total_fee,
    agg.total_tax,
    agg.high_value_returns,
    ROW_NUMBER() OVER (PARTITION BY agg.s_city ORDER BY agg.total_net_loss DESC) AS city_loss_rank
FROM agg
ORDER BY agg.total_net_loss DESC
LIMIT 100
