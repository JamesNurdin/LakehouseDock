WITH filtered_sales AS (
    SELECT *
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_list_price > 150.00
      AND cs.cs_quantity >= 2
)
SELECT
    i.i_brand,
    ca.ca_state,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt
FROM filtered_sales cs
JOIN tpcds.item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
JOIN tpcds.customer_address ca
  ON cr.cr_returning_addr_sk = ca.ca_address_sk
WHERE cr.cr_store_credit < 500.00
  AND i.i_units = 'Carton'
GROUP BY i.i_brand, ca.ca_state
ORDER BY total_sales DESC
LIMIT 100
