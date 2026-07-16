SELECT sub.i_brand,
       sub.i_category,
       COUNT(*) AS item_count
FROM (
    SELECT i.i_item_sk,
           i.i_brand,
           i.i_category,
           SUM(ss.ss_ext_sales_price + ws.ws_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    WHERE ss.ss_sold_date_sk = 2452128
      AND ws.ws_sold_date_sk = 2452331
      AND sr.sr_returned_date_sk = 2452065
      AND i.i_brand_id = 5003001
    GROUP BY i.i_item_sk, i.i_brand, i.i_category
) sub
GROUP BY sub.i_brand, sub.i_category
HAVING COUNT(*) > 5
