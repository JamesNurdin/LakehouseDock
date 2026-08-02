WITH items_proc AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_current_price,
        CONCAT(i.i_brand, '-', i.i_class) AS brand_class
    FROM tpcds.item i
    WHERE REGEXP_LIKE(i.i_item_desc, '(?i)metal')
      AND i.i_product_name LIKE '%Ultra%'
      AND i.i_current_price > (
          SELECT MAX(i2.i_current_price)
          FROM tpcds.item i2
          WHERE i2.i_brand = 'BrandX'
      )
),
sales_union AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit
    FROM tpcds.store_sales ss
    UNION ALL
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit
    FROM tpcds.web_sales ws
)
SELECT
    ip.i_item_id,
    ip.i_product_name,
    ip.brand_class,
    REGEXP_EXTRACT(ip.i_item_desc, '^(\\w+)') AS first_word,
    SUM(su.quantity) AS total_quantity,
    SUM(su.ext_sales_price) AS total_sales_amount,
    SUM(su.net_profit) AS total_profit
FROM items_proc ip
JOIN sales_union su ON su.item_sk = ip.i_item_sk
GROUP BY
    ip.i_item_id,
    ip.i_product_name,
    ip.brand_class,
    ip.i_item_desc
ORDER BY total_profit DESC
OFFSET 20 LIMIT 100
