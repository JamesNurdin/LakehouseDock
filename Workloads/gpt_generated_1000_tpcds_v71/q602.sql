WITH return_by_item AS (
    SELECT
        i.i_brand_id,
        i.i_manufact,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost,
        SUM(sr.sr_return_quantity) AS total_quantity,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM tpcds.store_returns sr
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_brand_id IN (3001002, 6008007, 1003001)
      AND i.i_manufact LIKE '%able'
      AND sr.sr_return_ship_cost > 100
    GROUP BY i.i_brand_id, i.i_manufact, i.i_category
),
brand_summary AS (
    SELECT
        i_brand_id,
        AVG(total_return_amt) AS avg_return_amt,
        SUM(total_ship_cost) AS sum_ship_cost,
        SUM(distinct_tickets) AS total_distinct_tickets
    FROM return_by_item
    GROUP BY i_brand_id
    HAVING SUM(total_ship_cost) > 5000
)
SELECT
    bs.i_brand_id,
    bs.avg_return_amt,
    bs.sum_ship_cost,
    bs.total_distinct_tickets
FROM brand_summary bs
ORDER BY bs.avg_return_amt DESC
LIMIT 100
