WITH item_sales AS (
    SELECT
        i.i_manufact,
        i.i_brand,
        i.i_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '(?i)eco')
      AND p.p_promo_name LIKE '%Summer%'
    GROUP BY i.i_manufact, i.i_brand, i.i_item_sk
)
SELECT
    COALESCE(CAST(isales.i_manufact AS VARCHAR), 'ALL_MANUFACTURERS') AS manufacturer,
    COALESCE(isales.i_brand, 'ALL_BRANDS')               AS brand,
    SUM(isales.total_sales)                              AS sales_amount,
    SUM(isales.total_profit)                             AS profit_amount,
    CASE
        WHEN SUM(isales.total_profit) > 10000 THEN 'High'
        ELSE 'Low'
    END                                                  AS profit_category,
    SUM(
        (SELECT COALESCE(SUM(wr.wr_return_quantity), 0)
         FROM web_returns wr
         WHERE wr.wr_item_sk = isales.i_item_sk)
    )                                                    AS total_return_quantity
FROM item_sales isales
GROUP BY ROLLUP (isales.i_manufact, isales.i_brand)
ORDER BY manufacturer, brand
LIMIT 100
