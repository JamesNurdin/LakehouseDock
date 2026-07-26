WITH promo_flag AS (
    SELECT
        p_item_sk,
        MAX(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS has_active_promo,
        AVG(p_cost) AS avg_promo_cost
    FROM promotion
    GROUP BY p_item_sk
),
item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        ca.ca_state,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_net_loss,
        pf.has_active_promo,
        pf.avg_promo_cost
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN promo_flag pf ON i.i_item_sk = pf.p_item_sk
    GROUP BY i.i_item_sk, i.i_product_name, i.i_category, ca.ca_state, pf.has_active_promo, pf.avg_promo_cost
)
SELECT
    i_item_sk,
    i_product_name,
    i_category,
    ca_state,
    total_return_amt,
    total_return_qty,
    total_net_loss - COALESCE(avg_promo_cost, 0) AS net_loss_adj,
    CASE WHEN has_active_promo = 1 THEN 'Active Promo' ELSE 'No Promo' END AS promo_status,
    RANK() OVER (PARTITION BY i_category ORDER BY total_return_amt DESC) AS category_return_rank
FROM item_returns
ORDER BY total_return_amt DESC
LIMIT 5
