WITH intersect_items AS (
        SELECT ss.ss_item_sk
        FROM tpcds.store_sales ss
        WHERE ss.ss_ext_sales_price > 1000
        INTERSECT
        SELECT sr.sr_item_sk
        FROM tpcds.store_returns sr
        WHERE sr.sr_return_amt > 100
    ),
    full_data AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_ticket_number,
            ss.ss_item_sk,
            ss.ss_ext_sales_price,
            sr.sr_returned_date_sk,
            sr.sr_ticket_number,
            sr.sr_item_sk,
            sr.sr_return_amt
        FROM tpcds.store_sales ss
        FULL OUTER JOIN tpcds.store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
        WHERE COALESCE(ss.ss_item_sk, sr.sr_item_sk) IN (SELECT ss_item_sk FROM intersect_items)
          AND NOT EXISTS (
              SELECT 1
              FROM tpcds.web_sales ws
              WHERE (ss.ss_item_sk IS NOT NULL AND ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk)
                 OR (sr.sr_item_sk IS NOT NULL AND ws.ws_item_sk = sr.sr_item_sk AND ws.ws_sold_date_sk = sr.sr_returned_date_sk)
          )
    ),
    item_info AS (
        SELECT i.i_item_id, i.i_item_sk
        FROM tpcds.item i
    )
SELECT
    ii.i_item_id AS item_id,
    COALESCE(fd.ss_ext_sales_price, 0) - COALESCE(fd.sr_return_amt, 0) AS metric,
    'store' AS source,
    (SELECT AVG(ws.ws_ext_sales_price)
     FROM tpcds.web_sales ws
     WHERE ws.ws_item_sk = ii.i_item_sk) AS avg_web_sales_price
FROM full_data fd
JOIN item_info ii ON ii.i_item_sk = COALESCE(fd.ss_item_sk, fd.sr_item_sk)

UNION DISTINCT

SELECT
    i2.i_item_id AS item_id,
    SUM(ws2.ws_ext_sales_price) AS metric,
    'web' AS source,
    NULL AS avg_web_sales_price
FROM tpcds.web_sales ws2
JOIN tpcds.item i2 ON ws2.ws_item_sk = i2.i_item_sk
WHERE ws2.ws_item_sk IN (SELECT ss_item_sk FROM intersect_items)
GROUP BY i2.i_item_id

ORDER BY metric DESC
LIMIT 100
