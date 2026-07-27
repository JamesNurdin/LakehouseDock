WITH joined_data AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_manufact_id,
        p.p_promo_name,
        cc.cc_name,
        c.c_customer_id,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_amt,
        sr.sr_net_loss,
        CASE
            WHEN cr.cr_net_loss > 1000 OR sr.sr_net_loss > 1000 THEN 'High'
            ELSE 'Low'
        END AS loss_category
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_class = 'furniture'
      AND i.i_manufact_id IN (169, 350)
      AND p.p_channel_dmail = 'Y'
),
agg AS (
    SELECT
        i_item_id,
        i_category,
        i_class,
        i_manufact_id,
        loss_category,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(cr_net_loss + sr_net_loss) AS total_net_loss
    FROM joined_data
    GROUP BY i_item_id, i_category, i_class, i_manufact_id, loss_category
)
SELECT
    i_item_id,
    i_category,
    i_class,
    i_manufact_id,
    loss_category,
    total_return_amount,
    total_store_return_amount,
    total_net_loss,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY loss_rank
LIMIT 100
