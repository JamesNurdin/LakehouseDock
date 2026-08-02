WITH unified_sales AS (
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_item_sk AS item_sk,
        CAST('store' AS varchar) AS sales_channel,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_sold_date_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_item_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_item_sk AS item_sk,
        CAST('web' AS varchar) AS sales_channel,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_sold_date_sk, i.i_item_id, i.i_product_name, i.i_category, i.i_item_sk
)
SELECT
    us.sold_date_sk,
    us.item_id,
    us.product_name,
    us.category,
    us.sales_channel,
    us.total_quantity,
    us.total_net_paid,
    (
        SELECT COUNT(*)
        FROM store_returns sr
        WHERE sr.sr_item_sk = us.item_sk
          AND sr.sr_returned_date_sk = us.sold_date_sk
    ) AS store_return_cnt,
    (
        SELECT COUNT(*)
        FROM web_returns wr
        WHERE wr.wr_item_sk = us.item_sk
          AND wr.wr_returned_date_sk = us.sold_date_sk
    ) AS web_return_cnt
FROM unified_sales us
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_item_sk = us.item_sk
      AND cr.cr_returned_date_sk = us.sold_date_sk
)
ORDER BY us.total_net_paid DESC
LIMIT 100
