WITH
    filtered_items AS (
        SELECT i_item_sk,
               i_item_desc,
               i_color,
               i_product_name
        FROM   item
        WHERE  i_color LIKE 'Red%'
    ),
    promo_info AS (
        SELECT p_promo_sk,
               p_promo_name,
               regexp_extract(p_promo_name, '(\\d{4})', 1) AS promo_year,
               CASE WHEN regexp_like(p_promo_name, 'DISCOUNT') THEN 'Discount' ELSE 'Other' END AS promo_type
        FROM   promotion
        WHERE  p_channel_email = 'N'
    ),
    sampled_inventory AS (
        SELECT *
        FROM   inventory
        TABLESAMPLE BERNOULLI (10)
    ),
    store_month AS (
        SELECT d.d_year,
               d.d_month_seq,
               si.i_item_sk,
               si.i_product_name,
               pc.product_code,
               SUM(ss.ss_ext_sales_price)      AS store_sales,
               SUM(ss.ss_net_profit)           AS store_profit,
               COUNT(*)                         AS store_txn,
               ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS store_rank
        FROM   store_sales ss
        JOIN   date_dim d       ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN   item si          ON ss.ss_item_sk = si.i_item_sk
        JOIN   filtered_items fi ON si.i_item_sk = fi.i_item_sk
        LEFT JOIN promo_info pi   ON ss.ss_promo_sk = pi.p_promo_sk
        LEFT JOIN LATERAL (
            SELECT regexp_extract(si.i_product_name, '(\\d+)', 1) AS product_code
        ) pc ON true
        GROUP BY d.d_year,
                 d.d_month_seq,
                 si.i_item_sk,
                 si.i_product_name,
                 pc.product_code
    ),
    web_month AS (
        SELECT d.d_year,
               d.d_month_seq,
               wi.i_item_sk,
               wi.i_product_name,
               SUM(ws.ws_ext_sales_price)      AS web_sales,
               SUM(ws.ws_net_profit)           AS web_profit,
               COUNT(*)                         AS web_txn,
               ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS web_rank
        FROM   web_sales ws
        JOIN   date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN   item wi          ON ws.ws_item_sk = wi.i_item_sk
        JOIN   filtered_items fi ON wi.i_item_sk = fi.i_item_sk
        LEFT JOIN promo_info pi   ON ws.ws_promo_sk = pi.p_promo_sk
        GROUP BY d.d_year,
                 d.d_month_seq,
                 wi.i_item_sk,
                 wi.i_product_name
    ),
    intersect_items AS (
        SELECT cs.cs_item_sk AS item_sk
        FROM   catalog_sales cs
        WHERE  cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
        INTERSECT
        SELECT ws.ws_item_sk
        FROM   web_sales ws
        WHERE  ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    )
SELECT COALESCE(sm.d_year, wm.d_year)                         AS year,
       COALESCE(sm.d_month_seq, wm.d_month_seq)               AS month_seq,
       COALESCE(sm.i_item_sk, wm.i_item_sk)                   AS item_sk,
       COALESCE(sm.i_product_name, wm.i_product_name)       AS product_name,
       COALESCE(sm.product_code, '')                        AS product_code,
       COALESCE(sm.store_sales, 0)                           AS store_sales,
       COALESCE(wm.web_sales, 0)                             AS web_sales,
       (COALESCE(sm.store_sales, 0) + COALESCE(wm.web_sales, 0)) AS total_sales,
       CASE WHEN (COALESCE(sm.store_profit, 0) + COALESCE(wm.web_profit, 0)) > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
       ROW_NUMBER() OVER (ORDER BY (COALESCE(sm.store_sales, 0) + COALESCE(wm.web_sales, 0)) DESC) AS overall_rank
FROM   store_month sm
FULL OUTER JOIN web_month wm
       ON sm.d_year = wm.d_year
      AND sm.d_month_seq = wm.d_month_seq
      AND sm.i_item_sk = wm.i_item_sk
WHERE  COALESCE(sm.i_item_sk, wm.i_item_sk) IN (SELECT item_sk FROM intersect_items)
  AND EXISTS ( SELECT 1
               FROM   sampled_inventory inv
               WHERE  inv.inv_item_sk = COALESCE(sm.i_item_sk, wm.i_item_sk)
                  AND inv.inv_quantity_on_hand > 0 )
ORDER BY total_sales DESC
LIMIT 100
