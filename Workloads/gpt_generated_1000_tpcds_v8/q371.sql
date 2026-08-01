WITH filtered_dates AS (
    SELECT d_date_sk, d_year, d_month_seq, d_dom
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1220
      AND d_dom IN (5, 9, 11)
),
sampled_inventory AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
customer_intersect AS (
    SELECT wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_tax > 15
    INTERSECT
    SELECT wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_quantity > 1
)
SELECT
    d.d_year,
    t.t_hour,
    i.inv_warehouse_sk,
    COUNT(DISTINCT wr.wr_order_number) AS order_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    CASE WHEN SUM(wr.wr_return_tax) > 100 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    (SELECT SUM(inv_quantity_on_hand)
     FROM inventory inv2
     WHERE inv2.inv_date_sk = d.d_date_sk) AS total_inventory_on_date
FROM filtered_dates d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
LEFT JOIN sampled_inventory i ON i.inv_date_sk = d.d_date_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND wr.wr_return_tax > 10
  AND i.inv_warehouse_sk IN (5, 16)
  AND wr.wr_returning_customer_sk IN (SELECT wr_returning_customer_sk FROM customer_intersect)
GROUP BY d.d_year, t.t_hour, i.inv_warehouse_sk, d.d_date_sk

UNION

SELECT
    d.d_year,
    t.t_hour,
    i.inv_warehouse_sk,
    COUNT(DISTINCT wr.wr_order_number) AS order_cnt,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    CASE WHEN SUM(wr.wr_return_tax) > 200 THEN 'VeryHighTax' ELSE 'ModerateTax' END AS tax_category,
    (SELECT SUM(inv_quantity_on_hand)
     FROM inventory inv2
     WHERE inv2.inv_date_sk = d.d_date_sk) AS total_inventory_on_date
FROM filtered_dates d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
LEFT JOIN sampled_inventory i ON i.inv_date_sk = d.d_date_sk
WHERE t.t_hour BETWEEN 18 AND 23
  AND wr.wr_return_tax BETWEEN 5 AND 15
  AND i.inv_warehouse_sk IN (3, 20)
  AND wr.wr_returning_customer_sk IN (SELECT wr_returning_customer_sk FROM customer_intersect)
GROUP BY d.d_year, t.t_hour, i.inv_warehouse_sk, d.d_date_sk

ORDER BY d_year, t_hour, inv_warehouse_sk
LIMIT 100
