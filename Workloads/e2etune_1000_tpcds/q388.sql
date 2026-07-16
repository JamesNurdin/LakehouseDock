WITH catalog_agg AS (
    SELECT
        i.i_category AS i_category,
        sm.sm_ship_mode_id AS ship_mode_id,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_total,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_qty,
        SUM(p.p_cost) AS catalog_promo_cost_total
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE cr.cr_return_amt_inc_tax > 500
      AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY i.i_category, sm.sm_ship_mode_id
),
web_agg AS (
    SELECT
        i.i_category AS i_category,
        'Web' AS ship_mode_id,
        COUNT(*) AS web_return_cnt,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_total,
        SUM(wr.wr_net_loss) AS web_net_loss,
        AVG(wr.wr_return_quantity) AS avg_web_qty,
        SUM(p.p_cost) AS web_promo_cost_total
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt_inc_tax > 500
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY i.i_category
)
SELECT
    COALESCE(ca.i_category, wa.i_category) AS category,
    COALESCE(ca.ship_mode_id, wa.ship_mode_id) AS ship_mode,
    COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(ca.catalog_return_total, 0) AS catalog_return_total,
    COALESCE(ca.catalog_net_loss, 0) AS catalog_net_loss,
    COALESCE(ca.catalog_promo_cost_total, 0) AS catalog_promo_cost_total,
    COALESCE(wa.web_return_cnt, 0) AS web_return_cnt,
    COALESCE(wa.web_return_total, 0) AS web_return_total,
    COALESCE(wa.web_net_loss, 0) AS web_net_loss,
    COALESCE(wa.web_promo_cost_total, 0) AS web_promo_cost_total,
    (COALESCE(ca.catalog_return_total, 0) + COALESCE(wa.web_return_total, 0)) AS total_return_amount,
    (COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    CASE 
        WHEN (COALESCE(ca.catalog_return_total, 0) + COALESCE(wa.web_return_total, 0)) = 0 THEN 0
        ELSE ((COALESCE(ca.catalog_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) / 
              (COALESCE(ca.catalog_return_total, 0) + COALESCE(wa.web_return_total, 0))) * 100
    END AS loss_ratio_percent,
    RANK() OVER (ORDER BY (COALESCE(ca.catalog_return_total, 0) + COALESCE(wa.web_return_total, 0)) DESC) AS return_rank
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
    ON ca.i_category = wa.i_category
ORDER BY total_return_amount DESC
LIMIT 20
