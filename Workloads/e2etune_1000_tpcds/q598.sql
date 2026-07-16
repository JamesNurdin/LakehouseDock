WITH filtered_returns AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_refunded_addr_sk,
        cr.cr_call_center_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_net_profit,
        cs.cs_promo_sk
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE cr.cr_call_center_sk = 22
      AND cr.cr_refunded_addr_sk IN (4577336, 2757029)
),
promo_agg AS (
    SELECT
        p.p_promo_name,
        p.p_purpose,
        fr.cr_returned_date_sk,
        COUNT(DISTINCT fr.cr_order_number) AS num_returns,
        SUM(fr.cr_return_amount) AS total_return_amount,
        SUM(fr.cr_store_credit) AS total_store_credit,
        SUM(fr.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(fr.cs_net_profit) AS total_net_profit,
        AVG(fr.cs_net_profit) AS avg_net_profit
    FROM filtered_returns fr
    JOIN promotion p
        ON fr.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.p_promo_name, p.p_purpose, fr.cr_returned_date_sk
    HAVING SUM(fr.cr_return_amount) > 1000
)
SELECT
    pa.p_promo_name,
    pa.p_purpose,
    pa.cr_returned_date_sk AS return_date_key,
    pa.num_returns,
    pa.total_return_amount,
    pa.total_store_credit,
    pa.total_net_paid,
    pa.total_net_profit,
    pa.avg_net_profit,
    RANK() OVER (PARTITION BY pa.cr_returned_date_sk ORDER BY pa.total_return_amount DESC) AS return_amount_rank
FROM promo_agg pa
ORDER BY pa.total_return_amount DESC
LIMIT 20
