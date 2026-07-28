WITH filtered_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returning_customer_sk,
        wr.wr_return_amt,
        wr.wr_return_tax,
        wr.wr_return_quantity,
        wr.wr_return_ship_cost
    FROM tpcds.web_returns wr
    WHERE wr.wr_returning_customer_sk = 11021556
      AND wr.wr_return_amt > 100.00
      AND wr.wr_return_ship_cost < 800.00
)
SELECT
    i.i_brand,
    i.i_class,
    SUM(fr.wr_return_amt) AS total_return_amount,
    AVG(fr.wr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(fr.wr_return_ship_cost) AS min_ship_cost,
    MAX(fr.wr_return_ship_cost) AS max_ship_cost,
    (SELECT MAX(i2.i_current_price)
     FROM tpcds.item i2
     WHERE i2.i_brand = i.i_brand) AS max_brand_price,
    CASE WHEN GROUPING(i.i_brand) = 1 THEN 'All Brands' ELSE i.i_brand END AS brand_group,
    CASE WHEN GROUPING(i.i_class) = 1 THEN 'All Classes' ELSE i.i_class END AS class_group
FROM filtered_returns fr
JOIN tpcds.item i
  ON fr.wr_item_sk = i.i_item_sk
WHERE i.i_manager_id = 23
  AND i.i_size = 'medium'
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_amt > 5000.00
    )
GROUP BY GROUPING SETS ((i.i_brand, i.i_class), (i.i_brand), ())
HAVING SUM(fr.wr_return_amt) > 200.00
ORDER BY total_return_amount DESC
LIMIT 100
