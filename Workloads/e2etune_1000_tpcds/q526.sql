SELECT
    city,
    state,
    market_id,
    num_call_centers,
    total_quantity,
    avg_quantity,
    RANK() OVER (ORDER BY total_quantity DESC) AS qty_rank
FROM (
    SELECT
        cc.cc_city AS city,
        cc.cc_state AS state,
        cc.cc_mkt_id AS market_id,
        COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM call_center cc
    JOIN inventory inv
        ON cc.cc_open_date_sk = inv.inv_date_sk
    WHERE cc.cc_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND inv.inv_quantity_on_hand > 0
        AND cc.cc_state IS NOT NULL
    GROUP BY cc.cc_city, cc.cc_state, cc.cc_mkt_id
) sub
WHERE total_quantity > 1000
ORDER BY qty_rank
LIMIT 25
