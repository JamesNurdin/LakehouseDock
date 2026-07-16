WITH returns_summary AS (
    SELECT
        s.s_store_id,
        s.s_state,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        ca_ref.ca_city AS refunded_city,
        ca_ret.ca_city AS returning_city,
        COUNT(*) AS total_returns,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(p_start.p_cost) AS avg_promo_start_cost,
        AVG(p_end.p_cost) AS avg_promo_end_cost
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret
        ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN promotion p_start
        ON p_start.p_start_date_sk = d.d_date_sk
    JOIN promotion p_end
        ON p_end.p_end_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_country = 'United States'
    GROUP BY
        s.s_store_id,
        s.s_state,
        s.s_city,
        d.d_year,
        d.d_month_seq,
        d.d_date,
        ca_ref.ca_city,
        ca_ret.ca_city
)
SELECT
    s_store_id,
    s_state,
    s_city,
    d_year,
    d_month_seq,
    d_date,
    refunded_city,
    returning_city,
    total_returns,
    total_net_loss,
    avg_promo_start_cost,
    avg_promo_end_cost,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY d_date) AS return_sequence
FROM returns_summary
ORDER BY total_net_loss DESC
LIMIT 100
