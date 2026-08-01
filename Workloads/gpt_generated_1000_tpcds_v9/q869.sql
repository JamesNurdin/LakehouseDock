WITH agg AS (
    SELECT
        cc.cc_state,
        i.i_manufact_id,
        i.i_formulation,
        p.p_promo_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_amount_category
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE cr.cr_call_center_sk IN (8, 38)
      AND cr.cr_return_tax > 10.00
      AND i.i_manufact_id = 169
      AND i.i_formulation LIKE '%blue%'
      AND cc.cc_county = 'Fairfield County'
    GROUP BY cc.cc_state, i.i_manufact_id, i.i_formulation, p.p_promo_name
    HAVING SUM(cr.cr_return_amount) > 100
)
SELECT
    agg.cc_state,
    agg.i_manufact_id,
    agg.i_formulation,
    agg.p_promo_name,
    agg.total_return_amount,
    agg.avg_return_tax,
    agg.distinct_orders,
    agg.return_amount_category,
    ROW_NUMBER() OVER (ORDER BY agg.total_return_amount DESC) AS rn_by_total
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
