WITH
  sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)   -- sample ~5% of rows
    WHERE ss_coupon_amt > 0
      AND ss_list_price BETWEEN 20 AND 80
      AND ss_quantity >= 1
      AND ss_ext_sales_price > 100
      AND ss_net_profit > 0
  ),
  item_union AS (
    SELECT i_item_sk, i_category
    FROM item
    WHERE i_units = 'Lb'
    UNION
    SELECT i_item_sk, i_category
    FROM item
    WHERE i_units = 'Pound'
  ),
  item_except AS (
    (SELECT i_item_sk FROM item)
    EXCEPT
    (SELECT i_item_sk FROM item WHERE i_rec_end_date < DATE '2000-01-01')
  )
SELECT
  ca.ca_city,
  i.i_category,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(ss.ss_net_profit) AS total_profit,
  AVG(ss.ss_coupon_amt) AS avg_coupon_amt,
  (SELECT AVG(ss2.ss_ext_discount_amt) FROM store_sales ss2) AS avg_discount_overall,
  RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank,
  CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Medium' END AS profit_level
FROM sampled_sales ss
FULL OUTER JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
FULL OUTER JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
WHERE i.i_category IN (SELECT i_category FROM item_union)
  AND i.i_item_sk IN (SELECT i_item_sk FROM item_except)
  AND ca.ca_state = 'CA'
  AND ca.ca_zip LIKE '9___'
  AND ss.ss_ext_tax > 0
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_ticket_number = ss.ss_ticket_number
          AND s2.ss_quantity > 10
      )
GROUP BY ROLLUP (ca.ca_city, i.i_category)
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
