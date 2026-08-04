WITH filtered_returns AS (
   SELECT
       wr.wr_item_sk,
       wr.wr_refunded_customer_sk,
       wr.wr_returning_customer_sk,
       wr.wr_reason_sk,
       wr.wr_return_quantity,
       wr.wr_return_amt,
       wr.wr_net_loss,
       wr.wr_order_number,
       wr.wr_returned_date_sk
   FROM web_returns wr
   WHERE wr.wr_return_quantity > 1
     AND wr.wr_return_amt > 10
     AND wr.wr_returned_date_sk BETWEEN 2452500 AND 2452600
),
common_items AS (
   SELECT fr.wr_item_sk FROM filtered_returns fr
   INTERSECT
   SELECT i.i_item_sk FROM item i
   WHERE i.i_container = 'Unknown'
     AND i.i_manufact = 'esecallyable'
)
SELECT
    c_ref.c_email_address,
    c_ref.c_birth_month,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    COUNT(DISTINCT fr.wr_order_number) AS distinct_orders,
    COUNT(DISTINCT i.i_brand_id) AS distinct_brands,
    SUM(fr.wr_return_amt) AS total_return_amt,
    AVG(fr.wr_net_loss) AS avg_net_loss,
    MIN(fr.wr_return_quantity) AS min_qty,
    MAX(fr.wr_return_quantity) AS max_qty
FROM filtered_returns fr
FULL OUTER JOIN item i
   ON fr.wr_item_sk = i.i_item_sk
LEFT JOIN customer c_ref
   ON fr.wr_refunded_customer_sk = c_ref.c_customer_sk
LEFT JOIN customer c_ret
   ON fr.wr_returning_customer_sk = c_ret.c_customer_sk
LEFT JOIN reason r
   ON fr.wr_reason_sk = r.r_reason_sk
WHERE i.i_item_sk IN (SELECT wr_item_sk FROM common_items)
  AND c_ref.c_birth_month IN (1, 3, 5)
  AND c_ref.c_last_review_date > 2452500
  AND r.r_reason_desc LIKE '%gift%'
  AND EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c_ref.c_customer_sk
          AND wr2.wr_return_amt > 100
      )
GROUP BY
    c_ref.c_email_address,
    c_ref.c_birth_month,
    i.i_brand,
    i.i_category,
    r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 100
