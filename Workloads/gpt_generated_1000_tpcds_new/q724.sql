WITH store_items AS (
    SELECT DISTINCT sr.sr_item_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND sr.sr_item_sk IN (
          SELECT p.p_item_sk
          FROM promotion p
          WHERE p.p_channel_email = 'N'
      )
),
web_items AS (
    SELECT DISTINCT wr.wr_item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
),
store_not_web AS (
    SELECT sr_item_sk AS item_sk
    FROM store_items
    EXCEPT
    SELECT wr_item_sk AS item_sk
    FROM web_items
),
full_join AS (
    SELECT 
        COALESCE(sr.sr_item_sk, wr.wr_item_sk) AS item_sk,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amt,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS web_return_amt,
        CASE 
            WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 0 THEN 'Loss'
            ELSE 'Gain'
        END AS net_loss_category,
        CASE 
            WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 0 THEN 'Loss'
            ELSE 'Gain'
        END AS loss_flag
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
        ON sr.sr_item_sk = wr.wr_item_sk
    GROUP BY 
        COALESCE(sr.sr_item_sk, wr.wr_item_sk),
        CASE 
            WHEN COALESCE(sr.sr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) > 0 THEN 'Loss'
            ELSE 'Gain'
        END
)
SELECT
    item_sk,
    NULL AS store_return_amt,
    NULL AS web_return_amt,
    NULL AS net_loss_category
FROM store_not_web
UNION ALL
SELECT
    item_sk,
    store_return_amt,
    web_return_amt,
    net_loss_category
FROM full_join
ORDER BY item_sk
LIMIT 100
