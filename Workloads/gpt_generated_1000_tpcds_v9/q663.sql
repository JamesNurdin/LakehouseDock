WITH filtered_items AS (
    SELECT i_item_sk, i_item_id, i_product_name
    FROM item
    WHERE i_current_price BETWEEN 10 AND 100
)

SELECT
    'store' AS return_channel,
    fi.i_item_id,
    fi.i_product_name,
    sr_agg.total_return_amount,
    sr_agg.total_return_quantity
FROM (
    SELECT sr.sr_item_sk AS item_sk,
           SUM(sr.sr_return_amt) AS total_return_amount,
           SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451080 AND 2451089
    GROUP BY sr.sr_item_sk
) sr_agg
JOIN filtered_items fi ON sr_agg.item_sk = fi.i_item_sk

UNION ALL

SELECT
    'web' AS return_channel,
    fi.i_item_id,
    fi.i_product_name,
    wr_agg.total_return_amount,
    wr_agg.total_return_quantity
FROM (
    SELECT wr.wr_item_sk AS item_sk,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_return_quantity) AS total_return_quantity
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2451080 AND 2451089
    GROUP BY wr.wr_item_sk
) wr_agg
JOIN filtered_items fi ON wr_agg.item_sk = fi.i_item_sk

ORDER BY total_return_amount DESC
LIMIT 100
