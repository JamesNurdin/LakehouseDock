WITH filtered_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour BETWEEN 9 AND 17
      AND t_minute IN (0, 15, 30, 45)
)
SELECT
    cr.cr_item_sk AS item_sk,
    cr.cr_return_amount AS return_amount,
    cr.cr_net_loss AS net_loss,
    (
        SELECT avg(ss.ss_net_profit)
        FROM store_sales ss
        WHERE ss.ss_item_sk = cr.cr_item_sk
    ) AS avg_item_profit,
    'catalog' AS return_channel
FROM catalog_returns cr
JOIN filtered_time ft ON cr.cr_returned_time_sk = ft.t_time_sk
WHERE cr.cr_return_amount > 50
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = cr.cr_item_sk
          AND ss2.ss_quantity > 5
    )
UNION ALL
SELECT
    sr.sr_item_sk AS item_sk,
    sr.sr_return_amt AS return_amount,
    sr.sr_net_loss AS net_loss,
    (
        SELECT avg(ss.ss_net_profit)
        FROM store_sales ss
        WHERE ss.ss_item_sk = sr.sr_item_sk
    ) AS avg_item_profit,
    'store' AS return_channel
FROM store_returns sr
JOIN filtered_time ft ON sr.sr_return_time_sk = ft.t_time_sk
WHERE sr.sr_return_amt > 50
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = sr.sr_item_sk
          AND ss2.ss_quantity > 5
    )
LIMIT 100
