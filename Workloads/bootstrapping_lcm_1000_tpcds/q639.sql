WITH aggregated AS (
    SELECT d.d_year,
           d.d_month_seq,
           s.s_state,
           s.s_market_desc,
           s.s_floor_space,
           sum(wr.wr_return_amt) AS total_return_amount,
           sum(wr.wr_net_loss) AS total_net_loss,
           sum(i.inv_quantity_on_hand) AS total_inventory_quantity,
           avg(i.inv_quantity_on_hand) AS avg_inventory_quantity,
           count(DISTINCT i.inv_item_sk) AS distinct_inventory_items,
           count(DISTINCT wr.wr_order_number) AS distinct_return_orders,
           sum(p.p_cost) AS total_promotion_cost,
           count(DISTINCT p.p_promo_id) AS distinct_promotions,
           min(p.p_cost) AS min_promotion_cost,
           max(p.p_cost) AS max_promotion_cost,
           case when sum(wr.wr_return_amt) > 5000 then 'HIGH' else 'LOW' end AS return_volume_category
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
                     AND d.d_date_sk <= p.p_end_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_month_seq, s.s_state, s.s_market_desc, s.s_floor_space
)
SELECT *
FROM (
    SELECT a.*,
           row_number() OVER (PARTITION BY a.s_state ORDER BY a.total_return_amount DESC) AS state_rank
    FROM aggregated a
) ranked
WHERE state_rank = 1
ORDER BY d_year DESC, d_month_seq
LIMIT 100
