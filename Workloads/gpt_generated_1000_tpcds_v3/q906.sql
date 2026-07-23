WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_net_profit,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_item_desc,
        i.i_product_name,
        REGEXP_EXTRACT(i.i_item_id, '([A-Z]+)$', 1) AS item_suffix,
        d.d_year
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2022
      AND s.s_state = 'CA'
      AND s.s_store_name LIKE '%Store%'
      AND REGEXP_LIKE(i.i_item_desc, '(?i)Premium')
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          JOIN date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
          WHERE ws.ws_bill_customer_sk = c.c_customer_sk
            AND wd.d_year = 2022
            AND ws.ws_ext_ship_cost > 100
      )
)
SELECT
    fs.s_store_id,
    fs.s_store_name,
    fs.item_suffix,
    CONCAT(fs.s_store_name, ' - ', fs.i_product_name) AS store_product_label,
    SUM(fs.ss_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(fs.ss_net_profit) > 100000 THEN 'High'
        WHEN SUM(fs.ss_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_tier
FROM filtered_sales fs
GROUP BY fs.s_store_id, fs.s_store_name, fs.item_suffix, fs.i_product_name
ORDER BY total_net_profit DESC
