WITH filtered_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand, inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 50
), items_without_returns AS (
    SELECT inv_item_sk
    FROM filtered_inventory
    EXCEPT
    SELECT DISTINCT wr_item_sk
    FROM web_returns
    WHERE wr_returned_date_sk = 2450927
)
SELECT
    d.d_year,
    cd.cd_gender,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    MIN(wr.wr_return_amt) AS min_return_amount,
    MAX(wr.wr_return_amt) AS max_return_amount,
    CASE 
        WHEN SUM(wr.wr_return_amt) > (
            SELECT AVG(wr2.wr_return_amt)
            FROM web_returns wr2
        ) THEN 'Above Avg Total'
        ELSE 'Below Avg Total'
    END AS total_amount_category,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_label
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN filtered_inventory i ON d.d_date_sk = i.inv_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 1999
  AND i.inv_quantity_on_hand > 100
  AND s.s_state = 'CA'
  AND ws.web_class = 'Unknown'
  AND cd.cd_marital_status = 'M'
  AND NOT EXISTS (
      SELECT 1
      FROM inventory i2
      WHERE i2.inv_item_sk = wr.wr_item_sk
        AND i2.inv_quantity_on_hand = 0
  )
  AND EXISTS (
      SELECT 1
      FROM items_without_returns iw
      WHERE iw.inv_item_sk = i.inv_item_sk
  )
GROUP BY GROUPING SETS (
    (d.d_year, cd.cd_gender),
    (d.d_year),
    (cd.cd_gender),
    ()
)
ORDER BY d.d_year DESC, total_return_amount DESC
LIMIT 100
