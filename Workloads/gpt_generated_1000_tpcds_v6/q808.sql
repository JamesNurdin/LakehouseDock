WITH high_price_items AS (
    SELECT i_item_sk,
           i_brand,
           i_product_name
    FROM   item
    WHERE  i_current_price > 1000
)
SELECT   hp.i_brand,
         SUM(sr.sr_net_loss)                                 AS total_net_loss,
         'store'                                              AS return_source,
         (SELECT AVG(i2.i_current_price)
            FROM   item i2
            WHERE  i2.i_brand = hp.i_brand)                 AS avg_brand_price
FROM     high_price_items hp
JOIN     store_returns sr ON sr.sr_item_sk = hp.i_item_sk
JOIN     store s          ON s.s_store_sk = sr.sr_store_sk
GROUP BY hp.i_brand

UNION ALL

SELECT   hp.i_brand,
         SUM(wr.wr_net_loss)                                 AS total_net_loss,
         'web'                                                AS return_source,
         (SELECT AVG(i2.i_current_price)
            FROM   item i2
            WHERE  i2.i_brand = hp.i_brand)                 AS avg_brand_price
FROM     high_price_items hp
JOIN     web_returns wr ON wr.wr_item_sk = hp.i_item_sk
JOIN     web_sales ws   ON ws.ws_item_sk = wr.wr_item_sk
                         AND ws.ws_order_number = wr.wr_order_number
JOIN     warehouse w    ON w.w_warehouse_sk = ws.ws_warehouse_sk
                         AND w.w_gmt_offset = -5.00
WHERE    ws.ws_ext_list_price > 5000
GROUP BY hp.i_brand

LIMIT 100
