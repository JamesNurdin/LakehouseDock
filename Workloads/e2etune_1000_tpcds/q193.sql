WITH store_return_stats AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_division_name,
        s.s_number_employees,
        s.s_floor_space,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        COUNT(*) AS cnt_returns
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state IN ('TN', 'LA', 'GA')
      AND sr.sr_returned_date_sk BETWEEN 2450800 AND 2451200
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_division_name,
        s.s_number_employees,
        s.s_floor_space
),
store_metrics AS (
    SELECT
        *,
        CASE WHEN s_number_employees > 0 THEN total_net_loss / s_number_employees ELSE NULL END AS net_loss_per_employee,
        CASE WHEN s_floor_space > 0 THEN total_net_loss / s_floor_space ELSE NULL END AS net_loss_per_sqft,
        ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS rn_state
    FROM store_return_stats
)
SELECT
    s_state,
    s_city,
    s_division_name,
    s_store_name,
    total_return_amt,
    total_net_loss,
    net_loss_per_employee,
    net_loss_per_sqft,
    avg_return_qty,
    cnt_returns
FROM store_metrics
WHERE rn_state <= 5
ORDER BY s_state, total_net_loss DESC
