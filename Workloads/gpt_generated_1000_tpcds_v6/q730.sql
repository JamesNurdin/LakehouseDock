WITH brand_refunds_1 AS (
  SELECT i.i_brand AS brand,
         SUM(wr.wr_refunded_cash) AS total_refund
  FROM item i
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  WHERE i.i_class_id = 12
    AND i.i_size = 'large'
    AND i.i_rec_end_date >= DATE '2000-01-01'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_quantity > 5
    )
  GROUP BY i.i_brand
),
brand_refunds_2 AS (
  SELECT i.i_brand AS brand,
         SUM(wr.wr_refunded_cash) AS total_refund
  FROM item i
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
  WHERE i.i_class_id = 13
    AND i.i_size = 'medium'
    AND i.i_rec_end_date < DATE '2001-01-01'
  GROUP BY i.i_brand
),
combined AS (
  SELECT brand, total_refund FROM brand_refunds_1
  UNION ALL
  SELECT brand, total_refund FROM brand_refunds_2
)
SELECT c.brand,
       c.total_refund
FROM combined c
WHERE c.total_refund > (SELECT avg(wr_refunded_cash) FROM web_returns)
ORDER BY c.total_refund DESC
LIMIT 100
