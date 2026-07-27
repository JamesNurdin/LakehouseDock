WITH returns_cte AS (
   SELECT
       d.d_date AS event_date,
       'return' AS source,
       SUM(wr.wr_return_amt) AS amount,
       SUM(wr.wr_return_quantity) AS quantity
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2001-01-01'
     AND d.d_date < DATE '2002-01-01'
     AND wr.wr_return_tax > 20
   GROUP BY d.d_date
),
inventory_cte AS (
   SELECT
       d.d_date AS event_date,
       'inventory' AS source,
       CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS amount,
       SUM(i.inv_quantity_on_hand) AS quantity
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_date >= DATE '2001-01-01'
     AND d.d_date < DATE '2002-01-01'
     AND w.w_country = 'United States'
   GROUP BY d.d_date
)
SELECT
    event_date,
    source,
    amount,
    quantity,
    ROW_NUMBER() OVER (PARTITION BY source ORDER BY amount DESC) AS rank_by_amount
FROM (
    SELECT event_date, source, amount, quantity FROM returns_cte
    UNION ALL
    SELECT event_date, source, amount, quantity FROM inventory_cte
) AS combined
ORDER BY event_date DESC, source
LIMIT 100
