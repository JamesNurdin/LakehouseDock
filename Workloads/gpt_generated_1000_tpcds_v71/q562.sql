WITH base AS (
    SELECT
        dr_cr.d_year AS d_year,
        dr_cr.d_month_seq AS d_month_seq,
        cp.cp_type AS cp_type,
        sm.sm_carrier AS sm_carrier,
        i.i_wholesale_cost AS i_wholesale_cost,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
    FROM catalog_returns cr
    JOIN date_dim dr_cr
        ON cr.cr_returned_date_sk = dr_cr.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
        AND dr_cr.d_date_sk = wr.wr_returned_date_sk
    JOIN date_dim dr_wr
        ON wr.wr_returned_date_sk = dr_wr.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
        i.i_wholesale_cost > 10
        AND sm.sm_carrier = 'MSC'
        AND cp.cp_type = 'A'
        AND dr_cr.d_fy_quarter_seq IN (15, 16)
        AND EXISTS (
            SELECT 1
            FROM store s
            WHERE s.s_closed_date_sk = dr_cr.d_date_sk
              AND s.s_state = 'CA'
        )
    GROUP BY
        dr_cr.d_year,
        dr_cr.d_month_seq,
        cp.cp_type,
        sm.sm_carrier,
        i.i_wholesale_cost
)
SELECT
    d_year,
    d_month_seq,
    total_net_loss,
    avg_yearly_net_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS rn_monthly_rank
FROM (
    SELECT
        d_year,
        d_month_seq,
        (catalog_net_loss + web_net_loss) AS total_net_loss,
        AVG(catalog_net_loss + web_net_loss) OVER (PARTITION BY d_year) AS avg_yearly_net_loss
    FROM base
) t
ORDER BY d_year DESC, total_net_loss DESC
LIMIT 100
