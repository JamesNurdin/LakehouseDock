WITH cr_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_ship_mode_sk AS ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(cr.cr_return_quantity) AS total_cr_return_quantity,
        SUM(cr.cr_fee) AS total_cr_fee,
        SUM(cr.cr_net_loss) AS total_cr_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS cr_order_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_ship_mode_sk
),
wr_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        SUM(wr.wr_return_amt) AS total_wr_return_amount,
        SUM(wr.wr_return_quantity) AS total_wr_return_quantity,
        SUM(wr.wr_fee) AS total_wr_fee,
        SUM(wr.wr_net_loss) AS total_wr_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS wr_order_cnt
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    sm.sm_carrier,
    sm.sm_type,
    s.s_market_desc,
    s.s_city,
    cr_agg.cr_order_cnt,
    wr_agg.wr_order_cnt,
    cr_agg.total_cr_return_amount,
    wr_agg.total_wr_return_amount,
    cr_agg.total_cr_net_loss,
    wr_agg.total_wr_net_loss,
    cr_agg.total_cr_fee,
    wr_agg.total_wr_fee,
    CASE
        WHEN (cr_agg.total_cr_return_quantity + wr_agg.total_wr_return_quantity) = 0 THEN 0
        ELSE (cr_agg.total_cr_return_amount + wr_agg.total_wr_return_amount) /
             (cr_agg.total_cr_return_quantity + wr_agg.total_wr_return_quantity)
    END AS avg_return_amount_per_quantity,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_year
        ORDER BY (cr_agg.total_cr_return_amount + wr_agg.total_wr_return_amount) DESC
    ) AS yearly_return_rank
FROM cr_agg
JOIN date_dim d ON cr_agg.date_sk = d.d_date_sk
JOIN ship_mode sm ON cr_agg.ship_mode_sk = sm.sm_ship_mode_sk
JOIN wr_agg ON wr_agg.date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
ORDER BY yearly_return_rank
LIMIT 50
