WITH returns_by_state AS (
    SELECT
        ca_state AS category,
        d_year AS year,
        SUM(sr_net_loss) AS metric
    FROM store_returns
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN time_dim ON store_returns.sr_return_time_sk = time_dim.t_time_sk
    JOIN customer_address ON store_returns.sr_addr_sk = customer_address.ca_address_sk
    WHERE d_year = 2001
      AND t_am_pm = 'AM'
    GROUP BY ca_state, d_year
),
promo_costs AS (
    SELECT
        p_promo_name AS category,
        d_start.d_year AS year,
        SUM(p_cost) AS metric
    FROM promotion
    JOIN date_dim AS d_start ON promotion.p_start_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 2001
      AND p_channel_email = 'Y'
    GROUP BY p_promo_name, d_start.d_year
)
SELECT category, year, metric FROM returns_by_state
UNION ALL
SELECT category, year, metric FROM promo_costs
ORDER BY year DESC, metric DESC
LIMIT 100
