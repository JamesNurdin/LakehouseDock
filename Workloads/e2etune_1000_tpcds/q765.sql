WITH promo_returns AS (
    SELECT
        p.p_promo_name AS promo_name,
        p.p_promo_id   AS promo_id,
        i.i_category   AS category,
        d.d_year       AS year,
        d.d_month_seq  AS month_seq,
        SUM(sr.sr_return_amt)   AS total_return_amount,
        COUNT(*)                AS return_cnt,
        AVG(sr.sr_return_amt)   AS avg_return_amount,
        SUM(sr.sr_net_loss)     AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p
        ON sr.sr_item_sk = p.p_item_sk
    WHERE d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      AND d.d_fy_year = 1902
      AND i.i_category = 'Electronics'
      AND p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_name,
        p.p_promo_id,
        i.i_category,
        d.d_year,
        d.d_month_seq
)
SELECT
    promo_name,
    promo_id,
    category,
    year,
    month_seq,
    total_return_amount,
    return_cnt,
    avg_return_amount,
    total_net_loss,
    RANK() OVER (PARTITION BY category ORDER BY total_return_amount DESC) AS promo_rank_in_category
FROM promo_returns
WHERE total_return_amount > 1000
ORDER BY total_return_amount DESC
LIMIT 10
