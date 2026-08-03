WITH sold_not_returned AS (
    SELECT DISTINCT ss_item_sk FROM store_sales
    EXCEPT
    SELECT DISTINCT sr_item_sk FROM store_returns
),
store_item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_net_paid_inc_tax) AS sales_net_paid,
        (SELECT COALESCE(SUM(sr.sr_return_amt), 0)
         FROM store_returns sr
         WHERE sr.sr_item_sk = i.i_item_sk) AS total_return_amt
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_list_price > 20
      AND p.p_discount_active = 'Y'
      AND ss.ss_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 50)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
    HAVING SUM(ss.ss_net_paid_inc_tax) > 500
),
web_item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_net_paid_inc_tax) AS sales_net_paid,
        (SELECT COALESCE(SUM(sr.sr_return_amt), 0)
         FROM store_returns sr
         WHERE sr.sr_item_sk = i.i_item_sk) AS total_return_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_list_price > 20
      AND p.p_discount_active = 'Y'
      AND ws.ws_item_sk IN (SELECT i2.i_item_sk FROM item i2 WHERE i2.i_current_price > 50)
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
    HAVING SUM(ws.ws_net_paid_inc_tax) > 500
)
SELECT
    si.i_item_id,
    si.i_item_desc,
    si.sales_net_paid,
    si.total_return_amt
FROM (
    SELECT * FROM store_item_sales
    UNION ALL
    SELECT * FROM web_item_sales
) si
WHERE si.i_item_sk IN (SELECT ss_item_sk FROM sold_not_returned)
ORDER BY si.sales_net_paid DESC
LIMIT 100
