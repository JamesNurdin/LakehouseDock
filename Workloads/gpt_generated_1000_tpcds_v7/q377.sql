WITH base AS (
    SELECT
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        i.i_item_id,
        i.i_color,
        i.i_current_price,
        d.d_year,
        d.d_month_seq,
        r.r_reason_id,
        sm.sm_type,
        w.w_state,
        wp.wp_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND i.i_color IN ('pink', 'yellow')
      AND i.i_current_price > 50
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND wp.wp_type = 'Content'
),
agg AS (
    SELECT
        i_item_id,
        d_year,
        SUM(cr_return_amount) + SUM(sr_return_amt) + SUM(wr_return_amt) AS total_return_amount
    FROM base
    GROUP BY i_item_id, d_year
),
ranked AS (
    SELECT
        i_item_id,
        d_year,
        total_return_amount,
        RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS yearly_rank
    FROM agg
)
SELECT
    i_item_id,
    d_year,
    total_return_amount,
    yearly_rank,
    CASE WHEN yearly_rank <= 5 THEN 'Top5' ELSE 'Other' END AS rank_group
FROM ranked
WHERE total_return_amount > 1000
ORDER BY d_year, yearly_rank
LIMIT 20
