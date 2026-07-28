/*
 * Goal: Summarize store return performance by store, state, and store size category, showing counts, total net loss, average tax, and a flag indicating whether the subtotal net loss exceeds the overall average net loss. The query uses a CTE for filtering, a scalar subquery for the overall average, a CASE expression for size categorisation, and a ROLLUP to produce subtotal rows.
 */
WITH filtered_data AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_tax,
        sr.sr_net_loss,
        ca.ca_state,
        s.s_store_name,
        s.s_floor_space,
        CASE
            WHEN s.s_floor_space > 20000 THEN 'Large'
            WHEN s.s_floor_space > 10000 THEN 'Medium'
            ELSE 'Small'
        END AS store_size_category
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_net_loss > 100.00
      AND sr.sr_return_tax >= 1.00
      AND s.s_manager = 'Jerry Brooks'
      AND ca.ca_state = 'CA'
      AND s.s_hours LIKE '8AM-4PM%'
)
SELECT
    s_store_name,
    ca_state,
    store_size_category,
    COUNT(DISTINCT sr_ticket_number) AS returns_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_return_tax) AS avg_return_tax,
    CASE
        WHEN SUM(sr_net_loss) > (SELECT AVG(sr_net_loss) FROM store_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_vs_avg
FROM filtered_data
GROUP BY ROLLUP (s_store_name, ca_state, store_size_category)
ORDER BY total_net_loss DESC NULLS LAST
LIMIT 100
