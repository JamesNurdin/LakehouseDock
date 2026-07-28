WITH base AS (
    SELECT
        dd.d_year,
        i.i_brand,
        s.s_state,
        sm.sm_type,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        i.i_current_price,
        i.i_item_sk
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk AND p.p_start_date_sk = dd.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2001
        AND dd.d_week_seq BETWEEN 10 AND 20
        AND i.i_current_price > 20
        AND s.s_tax_percentage <= 0.05
        AND sm.sm_type = 'AIR'
        AND ws.web_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
              AND p2.p_start_date_sk = dd.d_date_sk
        )
), agg AS (
    SELECT
        d_year,
        i_brand,
        s_state,
        sm_type,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(i_current_price) AS avg_price,
        MIN(cr_return_quantity) AS min_qty,
        MAX(cr_return_quantity) AS max_qty
    FROM base
    GROUP BY d_year, i_brand, s_state, sm_type
)
SELECT
    d_year,
    i_brand,
    s_state,
    sm_type,
    total_return_amount,
    return_cnt,
    avg_price,
    min_qty,
    max_qty,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS yearly_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
