WITH store_data AS (
  SELECT i.i_item_id AS item_id,
         'Store' AS return_channel,
         sr.sr_return_amt AS return_amount,
         ca.ca_city AS city
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  WHERE sr.sr_return_amt > (
          SELECT avg(sr2.sr_return_amt)
          FROM store_returns sr2
          WHERE sr2.sr_return_quantity > 1
        )
    AND i.i_manager_id IN (
          SELECT i_sub.i_manager_id
          FROM item i_sub
          WHERE i_sub.i_manager_id = 63
        )
),
web_data AS (
  SELECT i.i_item_id AS item_id,
         'Web' AS return_channel,
         wr.wr_return_amt AS return_amount,
         ca.ca_city AS city
  FROM web_returns wr
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_return_amt > (
          SELECT avg(wr2.wr_return_amt)
          FROM web_returns wr2
          WHERE wr2.wr_return_quantity > 1
        )
    AND EXISTS (
          SELECT 1
          FROM item i2
          WHERE i2.i_item_sk = wr.wr_item_sk
            AND i2.i_color = 'Red'
        )
    AND ca.ca_street_type IN (
          SELECT ca_sub.ca_street_type
          FROM customer_address ca_sub
          WHERE ca_sub.ca_street_type = 'Ave'
        )
)
SELECT item_id,
       return_channel,
       return_amount,
       city
FROM (
  SELECT item_id, return_channel, return_amount, city FROM store_data
  UNION
  SELECT item_id, return_channel, return_amount, city FROM web_data
) AS combined
ORDER BY return_amount DESC, item_id ASC
OFFSET 20 LIMIT 100
