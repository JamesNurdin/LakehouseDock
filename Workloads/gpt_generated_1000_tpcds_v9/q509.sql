WITH
  promo_returns AS (
    SELECT
      i.i_category,
      i.i_brand,
      SUM(sr.sr_return_quantity) AS total_quantity,
      SUM(sr.sr_return_amt) AS total_return_amount,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= DATE '2023-01-01'
    GROUP BY GROUPING SETS ((i.i_category, i.i_brand), (i.i_category), ())
  ),
  nonpromo_high_loss_returns AS (
    SELECT
      i.i_category,
      i.i_brand,
      SUM(sr.sr_return_quantity) AS total_quantity,
      SUM(sr.sr_return_amt) AS total_return_amount,
      SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date <= DATE '2023-01-01'
      AND NOT EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk)
      AND i.i_item_sk IN (
        SELECT sr2.sr_item_sk
        FROM store_returns sr2
        JOIN item i2 ON sr2.sr_item_sk = i2.i_item_sk
        WHERE sr2.sr_net_loss > 150
        EXCEPT
        SELECT p2.p_item_sk FROM promotion p2
      )
    GROUP BY GROUPING SETS ((i.i_category, i.i_brand), (i.i_category), ())
  )
SELECT *
FROM promo_returns
UNION ALL
SELECT *
FROM nonpromo_high_loss_returns
ORDER BY i_category, i_brand
LIMIT 100
