WITH returns_by_store_promo AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_city AS customer_city,
        ca.ca_state AS customer_state,
        dr.d_year,
        dr.d_month_seq,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        dp_end.d_date AS promo_end_date,
        ds.d_date AS store_closed_date,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(sr.sr_return_amt) / NULLIF(p.p_cost, 0) AS return_to_promo_cost_ratio
    FROM store_returns sr
    JOIN date_dim dr
        ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim ds
        ON s.s_closed_date_sk = ds.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = dr.d_date_sk
    JOIN date_dim dp_end
        ON p.p_end_date_sk = dp_end.d_date_sk
    WHERE dr.d_year = 2022
      AND p.p_discount_active = 'Y'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_city,
        ca.ca_state,
        dr.d_year,
        dr.d_month_seq,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        dp_end.d_date,
        ds.d_date
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    customer_city,
    customer_state,
    d_year,
    d_month_seq,
    p_promo_id,
    p_promo_name,
    p_cost,
    promo_end_date,
    store_closed_date,
    num_returns,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    return_to_promo_cost_ratio,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS net_loss_rank
FROM returns_by_store_promo
ORDER BY total_net_loss DESC
LIMIT 100
