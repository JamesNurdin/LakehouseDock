WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_quantity,
        cr.cr_order_number,
        sm.sm_type,
        sm.sm_carrier,
        sm.sm_ship_mode_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_order_number,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk,
        wsit.web_state
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE cr.cr_fee > 50
      AND cr.cr_return_quantity BETWEEN 1 AND 5
      AND sm.sm_type = 'EXPRESS'
      AND ws.ws_net_paid_inc_tax > 1000
      AND wsit.web_state = 'CA'
),
agg AS (
    SELECT
        sm.sm_type,
        wsit.web_state,
        sm.sm_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(ws.ws_net_paid_inc_tax) AS avg_sales_inc_tax,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        MAX(ws.ws_net_paid_inc_tax) AS max_sales_inc_tax,
        MIN(ws.ws_net_paid_inc_tax) AS min_sales_inc_tax,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
        ) AS avg_return_amount_by_mode
    FROM filtered cr
    JOIN ship_mode sm ON cr.sm_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws ON cr.ws_ship_mode_sk = ws.ws_ship_mode_sk
    JOIN web_site wsit ON cr.ws_web_site_sk = wsit.web_site_sk
    GROUP BY sm.sm_type, wsit.web_state, sm.sm_ship_mode_sk
)
SELECT
    agg.sm_type,
    agg.web_state,
    agg.total_return_amount,
    agg.avg_sales_inc_tax,
    agg.distinct_return_orders,
    agg.max_sales_inc_tax,
    agg.min_sales_inc_tax,
    agg.avg_return_amount_by_mode,
    ROW_NUMBER() OVER (PARTITION BY agg.sm_type ORDER BY agg.total_return_amount DESC) AS return_rank
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
