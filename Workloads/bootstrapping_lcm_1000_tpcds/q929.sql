WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT wr.wr_order_number) AS orders_returned,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT p.p_promo_id) AS distinct_promotions,
        MAX(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost END) AS max_active_promo_cost,
        AVG(p.p_cost) AS avg_promo_cost
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_city, s.s_state
    HAVING SUM(wr.wr_return_amt) > 1000
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.orders_returned,
    a.total_return_amount,
    a.total_return_tax,
    a.total_inventory_on_hand,
    a.distinct_promotions,
    a.max_active_promo_cost,
    a.avg_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_return_amount DESC) AS store_return_rank
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 50
