/*
Goal: Compute total net loss and return counts by state and income band for both store and web returns, classify loss severity, and provide subtotal rows using UNION ALL, a correlated subquery, CASE WHEN, and GROUPING SETS.
*/
WITH store_agg AS (
    SELECT
        ca.ca_state AS state,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS total_return_count
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_quantity > (
        SELECT AVG(sr2.sr_return_quantity)
        FROM store_returns sr2
        WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk
    )
    GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
),
web_agg AS (
    SELECT
        ca.ca_state AS state,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS total_return_count
    FROM web_returns wr
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_quantity > (
        SELECT AVG(wr2.wr_return_quantity)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_hdemo_sk = wr.wr_refunded_hdemo_sk
    )
    GROUP BY ca.ca_state, ib.ib_lower_bound, ib.ib_upper_bound
),
combined AS (
    SELECT state, income_lower, income_upper, total_net_loss, total_return_count FROM store_agg
    UNION ALL
    SELECT state, income_lower, income_upper, total_net_loss, total_return_count FROM web_agg
)
SELECT
    COALESCE(state, 'ALL STATES') AS state,
    income_lower,
    income_upper,
    SUM(total_net_loss) AS total_net_loss,
    SUM(total_return_count) AS total_return_count,
    CASE
        WHEN SUM(total_net_loss) > 20000 THEN 'HIGH'
        WHEN SUM(total_net_loss) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM combined
GROUP BY GROUPING SETS (
    (state, income_lower, income_upper),
    (state, income_lower),
    (state),
    ()
)
ORDER BY total_net_loss DESC
LIMIT 100
