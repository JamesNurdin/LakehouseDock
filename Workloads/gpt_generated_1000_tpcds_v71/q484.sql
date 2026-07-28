/*
Goal: Compare item‑level sales performance between the store and web channels for the year 2001, but only for items that have at least one catalog return. The query aggregates sales per item and channel, unions the two result sets, adds a scalar sub‑query showing the total number of store transactions, and orders the final list by sales amount.
*/
WITH store_agg AS (
    SELECT
        i.i_item_id        AS item_id,
        d.d_year           AS year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*)          AS txn_count
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d.d_date_sk
      )
    GROUP BY i.i_item_id, d.d_year
),
web_agg AS (
    SELECT
        i.i_item_id        AS item_id,
        d.d_year           AS year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*)          AS txn_count
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_item_sk = i.i_item_sk
      )
    GROUP BY i.i_item_id, d.d_year
)
SELECT
    combined.item_id,
    combined.year,
    combined.channel,
    combined.total_sales,
    combined.txn_count,
    (SELECT COUNT(*) FROM store_sales) AS total_store_transactions
FROM (
    SELECT
        item_id,
        year,
        'store' AS channel,
        total_sales,
        txn_count
    FROM store_agg
    UNION ALL
    SELECT
        item_id,
        year,
        'web'   AS channel,
        total_sales,
        txn_count
    FROM web_agg
) AS combined
ORDER BY combined.total_sales DESC
LIMIT 100
