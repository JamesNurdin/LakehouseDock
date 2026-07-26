WITH state_agg AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        COUNT(DISTINCT sr.sr_item_sk) AS distinct_items,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        AVG(i.i_current_price) AS avg_item_price
    FROM store_returns sr
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY ca.ca_state
)
SELECT
    ca_state,
    distinct_customers,
    distinct_items,
    total_return_qty,
    total_return_amt,
    avg_return_amt,
    avg_vehicle_count,
    avg_item_price,
    CASE
        WHEN total_return_amt > 100000 THEN 'High'
        WHEN total_return_amt > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    total_return_amt / SUM(total_return_amt) OVER () AS state_return_share,
    RANK() OVER (ORDER BY total_return_amt DESC) AS state_return_rank
FROM state_agg
ORDER BY state_return_rank
