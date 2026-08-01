WITH store_return_data AS (
    SELECT
        i.i_category AS category,
        r.r_reason_desc AS label,
        SUM(sr.sr_return_amt) AS total_amount,
        'store_return' AS source
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_category_id IN (1, 2, 3)
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand <= 0
      )
    GROUP BY GROUPING SETS (
        (i.i_category, r.r_reason_desc),
        (i.i_category),
        ()
    )
    HAVING SUM(sr.sr_return_amt) > 1000
),
web_sales_data AS (
    SELECT
        i.i_category AS category,
        ws_site.web_name AS label,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        'web_sales' AS source
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND i.i_category_id IN (1, 2, 3)
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand <= 0
      )
    GROUP BY GROUPING SETS (
        (i.i_category, ws_site.web_name),
        (i.i_category),
        ()
    )
    HAVING SUM(ws.ws_ext_sales_price) > 2000
)
SELECT
    category,
    label,
    total_amount,
    source
FROM (
    SELECT * FROM store_return_data
    UNION ALL
    SELECT * FROM web_sales_data
) AS combined
ORDER BY category, total_amount DESC
LIMIT 100
