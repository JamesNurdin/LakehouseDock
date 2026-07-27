WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_color,
        i.i_wholesale_cost,
        p.p_promo_name,
        p.p_cost,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss,
        (
            SELECT MAX(p2.p_cost)
            FROM tpcds.promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
        ) AS max_item_promo_cost
    FROM tpcds.item i
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = i.i_item_sk
    WHERE
        i.i_color = 'red'
        AND i.i_wholesale_cost > 0.5
        AND p.p_channel_email = 'N'
        AND EXISTS (
            SELECT 1
            FROM tpcds.promotion p3
            WHERE p3.p_item_sk = i.i_item_sk
              AND p3.p_discount_active = 'Y'
        )
),
agg AS (
    SELECT
        brand,
        promo_name,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        MAX(p_cost) AS max_promo_cost_in_group,
        MAX(max_item_promo_cost) AS max_item_promo_cost_overall
    FROM (
        SELECT
            i_brand AS brand,
            p_promo_name AS promo_name,
            sr_return_amt_inc_tax,
            sr_net_loss,
            p_cost,
            max_item_promo_cost
        FROM base
    ) a
    GROUP BY GROUPING SETS (
        (brand, promo_name),
        (brand),
        (promo_name),
        ()
    )
)
SELECT
    brand,
    promo_name,
    total_return_amt,
    total_net_loss,
    max_promo_cost_in_group,
    max_item_promo_cost_overall,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 100
