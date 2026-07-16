WITH daily_store_metrics AS (
    SELECT
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_floor_space,
        COUNT(DISTINCT wr.wr_order_number) AS num_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        AVG(p.p_cost) AS avg_promo_cost,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state = 'CA'
    GROUP BY
        d.d_date,
        d.d_year,
        d.d_month_seq,
        s.s_store_id,
        s.s_city,
        s.s_state,
        s.s_floor_space
)
SELECT
    d_date,
    d_year,
    d_month_seq,
    s_store_id,
    s_city,
    s_state,
    s_floor_space,
    num_returns,
    total_return_amount,
    total_return_tax,
    total_net_loss,
    total_return_quantity,
    total_inventory_on_hand,
    avg_promo_cost,
    promo_count,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM daily_store_metrics
ORDER BY return_amount_rank
LIMIT 100
