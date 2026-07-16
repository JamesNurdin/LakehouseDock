WITH promo_stats AS (
    SELECT
        p.p_item_sk AS item_sk,
        COUNT(*) FILTER (WHERE p.p_discount_active = 'Y') AS active_promo_cnt,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    GROUP BY p.p_item_sk
),
store_item_returns AS (
    SELECT
        sr.sr_store_sk,
        i.i_category,
        i.i_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND i.i_current_price > 100
      AND s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY sr.sr_store_sk, i.i_category, i.i_item_sk
)
SELECT
    s.s_store_name,
    s.s_state,
    r.i_category,
    r.total_return_qty,
    r.total_return_amt,
    r.total_net_loss,
    r.avg_return_amt,
    r.distinct_customers,
    ps.active_promo_cnt,
    ps.total_promo_cost,
    RANK() OVER (PARTITION BY s.s_state ORDER BY r.total_net_loss DESC) AS net_loss_rank_state
FROM store_item_returns r
JOIN store s ON r.sr_store_sk = s.s_store_sk
LEFT JOIN promo_stats ps ON r.i_item_sk = ps.item_sk
ORDER BY s.s_state, net_loss_rank_state
LIMIT 100
