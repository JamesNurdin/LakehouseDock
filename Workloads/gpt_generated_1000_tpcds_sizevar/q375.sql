WITH
  store_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  web_items AS (
    SELECT DISTINCT i.i_item_id
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  reason_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND sr.sr_reason_sk = 9
  )
SELECT i_item_id
FROM store_items
INTERSECT
SELECT i_item_id
FROM web_items
EXCEPT
SELECT i_item_id
FROM reason_items
ORDER BY i_item_id
