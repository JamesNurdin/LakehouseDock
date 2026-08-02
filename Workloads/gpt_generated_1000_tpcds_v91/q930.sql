/* Goal: Analyze store return performance by year, item category, and customer state, combining inventory, promotion, call center, and web page context. The query samples inventory, aggregates using a CUBE, applies multiple filters, includes a window ranking, a correlated subquery, a semi‑join, and pages the top results. */
WITH sampled_inventory AS (
    SELECT *
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

joined_data AS (
    SELECT 
        cc.cc_call_center_id,
        d.d_year,
        d.d_date,
        i.i_category,
        i.i_class,
        i.i_brand,
        ca.ca_state,
        hd.hd_vehicle_count,
        p.p_discount_active,
        t.t_meal_time,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        inv.inv_quantity_on_hand,
        wp.wp_url
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
        AND p.p_start_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2002
        AND i.i_category = 'Electronics'
        AND i.i_class_id IN (10, 12, 14)
        AND ca.ca_state = 'CA'
        AND hd.hd_vehicle_count >= 1
        AND p.p_discount_active = 'Y'
        AND t.t_meal_time = 'dinner'
        AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_item_sk = i.i_item_sk
              AND p2.p_discount_active = 'Y'
        )
),

agg_cubes AS (
    SELECT 
        d_year,
        i_category,
        ca_state,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_qty,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(*) AS transaction_count
    FROM joined_data
    GROUP BY CUBE (d_year, i_category, ca_state)
    HAVING SUM(sr_return_amt) > 0
),

ranked AS (
    SELECT 
        d_year,
        i_category,
        ca_state,
        total_return_amt,
        total_return_qty,
        avg_inventory_on_hand,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_by_year,
        (
            SELECT SUM(sr3.sr_return_amt)
            FROM store_returns sr3
            JOIN date_dim d3 ON sr3.sr_returned_date_sk = d3.d_date_sk
            WHERE d3.d_year = agg_cubes.d_year
        ) AS total_return_amt_all_same_year
    FROM agg_cubes
)
SELECT 
    d_year,
    i_category,
    ca_state,
    total_return_amt,
    total_return_qty,
    avg_inventory_on_hand,
    transaction_count,
    rank_by_year,
    total_return_amt_all_same_year
FROM ranked
WHERE rank_by_year <= 10
ORDER BY total_return_amt DESC
OFFSET 0 LIMIT 100
