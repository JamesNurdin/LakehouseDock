WITH aggregated AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_channel_email,
        COUNT(*) AS num_returns,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        AVG(hd_refunded.hd_vehicle_count) AS avg_vehicle_count_refunded,
        AVG(hd_returning.hd_dep_count) AS avg_dep_count_returning
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    LEFT JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    LEFT JOIN household_demographics hd_returning ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    WHERE cr.cr_return_quantity > 5
      AND cr.cr_return_tax > 0
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_category, i.i_brand, p.p_channel_email
    HAVING SUM(cr.cr_return_amount) > 500
),
ranked AS (
    SELECT
        i_category,
        i_brand,
        p_channel_email,
        num_returns,
        total_return_amount,
        total_net_loss,
        avg_return_tax,
        avg_vehicle_count_refunded,
        avg_dep_count_returning,
        RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
    FROM aggregated
)
SELECT *
FROM ranked
ORDER BY total_net_loss DESC
LIMIT 100
