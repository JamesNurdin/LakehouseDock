/*
Goal: Analyze catalog return losses by reason and shipping mode, compare them with store return losses, and classify catalog loss severity.
The query joins all five selected tables, uses a LEFT OUTER JOIN to preserve catalog returns without a matching ship mode, aggregates in a CTE, then aggregates again with additional filtering and a CASE expression.
*/
WITH base AS (
    SELECT
        r.r_reason_desc,
        sm.sm_type,
        cr.cr_returned_time_sk,
        t1.t_hour AS cr_hour,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        cr.cr_store_credit,
        cr.cr_reversed_charge,
        cr.cr_return_quantity,
        CASE
            WHEN cr.cr_net_loss > 1000 THEN 'HIGH'
            WHEN cr.cr_net_loss > 500  THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_level,
        COALESCE(sm.sm_contract, 'UNKNOWN') AS contract
    FROM catalog_returns cr
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim t1
        ON cr.cr_returned_date_sk = t1.t_time_sk
    WHERE cr.cr_return_amt_inc_tax > 100
      AND cr.cr_reversed_charge < 500
      AND cr.cr_store_credit BETWEEN 0 AND 500
      AND t1.t_hour >= 8
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND r.r_reason_desc IS NOT NULL
),
store_agg AS (
    SELECT
        r.r_reason_desc,
        t2.t_hour AS sr_hour,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_inc_tax,
        COUNT(*) AS store_return_cnt
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk
    WHERE sr.sr_return_ship_cost > 50
      AND sr.sr_store_credit < 1200
      AND sr.sr_return_tax >= 0
      AND t2.t_hour BETWEEN 8 AND 20
      AND r.r_reason_desc IS NOT NULL
    GROUP BY r.r_reason_desc, t2.t_hour
)
SELECT
    b.r_reason_desc,
    b.sm_type,
    b.loss_level,
    SUM(b.cr_net_loss) AS total_catalog_net_loss,
    SUM(COALESCE(sa.store_net_loss, 0)) AS total_store_net_loss,
    COUNT(*) AS catalog_return_cnt,
    AVG(b.cr_return_amt_inc_tax) AS avg_catalog_return_amt_inc_tax,
    CASE
        WHEN SUM(b.cr_net_loss) > 2000 THEN 'CATALOG_HIGH'
        ELSE 'CATALOG_NORMAL'
    END AS catalog_loss_category
FROM base b
LEFT JOIN store_agg sa
    ON b.r_reason_desc = sa.r_reason_desc
GROUP BY b.r_reason_desc, b.sm_type, b.loss_level
HAVING SUM(b.cr_net_loss) > 500
ORDER BY total_catalog_net_loss DESC
LIMIT 100
