WITH filtered AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_ship_cost,
        sr.sr_cdemo_sk,
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_manufact_id,
        i.i_container,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_gmt_offset,
        inv.inv_quantity_on_hand
    FROM tpcds.store_returns AS sr
    JOIN tpcds.item AS i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer_address AS ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.inventory AS inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (4, 6, 8)                                   -- predicate 1
      AND i.i_manufact_id = 264                                          -- predicate 2
      AND i.i_container = 'Unknown'                                      -- predicate 3
      AND ca.ca_location_type = 'apartment'                             -- predicate 4
      AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00                      -- predicate 5
      AND sr.sr_return_ship_cost > 0                                    -- predicate 6
      AND sr.sr_cdemo_sk > 1000000                                      -- predicate 7
      AND inv.inv_quantity_on_hand > 0                                   -- predicate 8
),
agg AS (
    SELECT
        i_category,
        i_brand,
        ca_state,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_ship_cost) AS avg_ship_cost,
        COUNT(*) AS return_cnt,
        MAX(inv_quantity_on_hand) AS max_qty_on_hand
    FROM filtered
    GROUP BY i_category, i_brand, ca_state
)
SELECT
    agg.i_category,
    agg.i_brand,
    agg.ca_state,
    agg.total_return_amount,
    agg.avg_ship_cost,
    agg.return_cnt,
    agg.max_qty_on_hand,
    ROW_NUMBER() OVER (PARTITION BY agg.i_category ORDER BY agg.total_return_amount DESC) AS category_brand_rank,
    CASE
        WHEN agg.total_return_amount > 50000 THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level,
    (SELECT COUNT(*) FROM filtered f2 WHERE f2.ca_state = agg.ca_state) AS state_return_count
FROM agg
ORDER BY agg.i_category, category_brand_rank
