WITH promo_item_returns AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_email,
        ca.ca_state,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    GROUP BY p.p_promo_sk, p.p_promo_name, p.p_cost, p.p_channel_email, ca.ca_state
)
SELECT
    p_promo_sk,
    p_promo_name,
    ca_state,
    total_return_amt,
    p_cost,
    total_return_amt / NULLIF(p_cost, 0) AS roi,
    CASE
        WHEN total_return_amt / NULLIF(p_cost, 0) > 2 THEN 'Highly Effective'
        WHEN total_return_amt / NULLIF(p_cost, 0) > 1 THEN 'Effective'
        ELSE 'Ineffective'
    END AS effectiveness,
    DENSE_RANK() OVER (ORDER BY total_return_amt / NULLIF(p_cost, 0) DESC) AS overall_roi_rank,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amt / NULLIF(p_cost, 0) DESC) AS state_roi_rank
FROM promo_item_returns
WHERE p_cost > 0
ORDER BY overall_roi_rank
LIMIT 10
