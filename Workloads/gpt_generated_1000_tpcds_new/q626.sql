/* goal: Identify high‑value catalog returns broken down by call center, shipping mode and warehouse, using regex and LIKE filters, array expansion, lateral string concatenation and CASE logic. */
WITH cs_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_sold_date_sk
    FROM catalog_sales cs
    WHERE cs.cs_call_center_sk IN (
        SELECT cc.cc_call_center_sk
        FROM call_center cc
        WHERE regexp_like(cc.cc_name, '^.*Center$')
          AND cc.cc_manager LIKE '%Charles%'
    )
),
cr_joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        ARRAY[CAST(cr.cr_return_quantity AS double), CAST(cr.cr_return_amount AS double)] AS metrics_arr,
        CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag
    FROM catalog_returns cr
    WHERE cr.cr_order_number IN (SELECT cs_order_number FROM cs_filtered)
),
reason_extracted AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS first_word
    FROM reason r
),
ship_mode_filtered AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_ship_mode_id,
        sm.sm_contract
    FROM ship_mode sm
    WHERE sm.sm_contract LIKE '%I3u%'
),
final_prep AS (
    SELECT
        cs.cs_call_center_sk,
        cc.cc_name,
        sm.sm_ship_mode_id,
        wh.w_warehouse_name,
        re.first_word,
        cr.loss_flag,
        cr.metrics_arr,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number
    FROM cr_joined cr
    JOIN cs_filtered cs ON cr.cr_order_number = cs.cs_order_number
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN reason_extracted re ON cr.cr_reason_sk = re.r_reason_sk
    JOIN ship_mode_filtered smf ON sm.sm_ship_mode_sk = smf.sm_ship_mode_sk
    -- expand the array created in cr_joined
    CROSS JOIN UNNEST(cr.metrics_arr) AS u(metric)
    -- lateral sub‑query that builds a concatenated label
    JOIN LATERAL (
        SELECT concat(cc.cc_name, ' - ', sm.sm_ship_mode_id) AS combined_label
    ) AS lc ON true
    WHERE u.metric > 0
)
SELECT
    fp.cs_call_center_sk,
    fp.cc_name,
    fp.sm_ship_mode_id,
    fp.w_warehouse_name,
    fp.first_word,
    fp.loss_flag,
    SUM(fp.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT fp.cr_order_number) AS distinct_orders,
    MAX(fp.cr_net_loss) AS max_net_loss
FROM final_prep fp
GROUP BY
    fp.cs_call_center_sk,
    fp.cc_name,
    fp.sm_ship_mode_id,
    fp.w_warehouse_name,
    fp.first_word,
    fp.loss_flag
ORDER BY total_return_amount DESC
LIMIT 100
