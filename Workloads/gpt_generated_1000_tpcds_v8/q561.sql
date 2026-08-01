WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
full_joined AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        sr.sr_ticket_number AS ret_ticket_number,
        sr.sr_item_sk AS ret_item_sk,
        sr.sr_store_sk AS ret_store_sk,
        sr.sr_net_loss
    FROM sampled_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    store_sk,
    total_sales,
    total_loss
FROM (
    SELECT
        COALESCE(ss_store_sk, ret_store_sk) AS store_sk,
        SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(sr_net_loss, 0)) AS total_loss
    FROM full_joined fj
    WHERE COALESCE(ss_ext_sales_price, 0) > 50
      AND EXISTS (
          SELECT 1
          FROM store_returns r
          WHERE r.sr_store_credit > 100
            AND r.sr_ticket_number = fj.ss_ticket_number
      )
    GROUP BY COALESCE(ss_store_sk, ret_store_sk)

    UNION

    SELECT
        COALESCE(ss_store_sk, ret_store_sk) AS store_sk,
        SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(sr_net_loss, 0)) AS total_loss
    FROM full_joined fj
    WHERE fj.ret_ticket_number IS NULL
      AND fj.ss_ticket_number NOT IN (SELECT sr_ticket_number FROM store_returns)
    GROUP BY COALESCE(ss_store_sk, ret_store_sk)
) AS u
ORDER BY total_sales DESC
LIMIT 100
