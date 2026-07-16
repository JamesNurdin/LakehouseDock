WITH
date_2001 AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
),
store_agg AS (
    SELECT ss_item_sk AS item_sk,
           SUM(ss_net_profit) AS store_net_profit,
           SUM(ss_quantity) AS store_qty,
           COUNT(*) AS store_txn
    FROM store_sales ss
    JOIN date_2001 d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss_item_sk
),
catalog_agg AS (
    SELECT cs_item_sk AS item_sk,
           SUM(cs_net_profit) AS catalog_net_profit,
           SUM(cs_quantity) AS catalog_qty,
           COUNT(*) AS catalog_txn
    FROM catalog_sales cs
    JOIN date_2001 d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs_item_sk
),
web_agg AS (
    SELECT ws_item_sk AS item_sk,
           SUM(ws_net_profit) AS web_net_profit,
           SUM(ws_quantity) AS web_qty,
           COUNT(*) AS web_txn
    FROM web_sales ws
    JOIN date_2001 d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws_item_sk
),
sales_combined AS (
    SELECT COALESCE(s.item_sk, c.item_sk, w.item_sk) AS item_sk,
           s.store_net_profit,
           c.catalog_net_profit,
           w.web_net_profit,
           s.store_qty,
           c.catalog_qty,
           w.web_qty,
           s.store_txn,
           c.catalog_txn,
           w.web_txn
    FROM store_agg s
    FULL OUTER JOIN catalog_agg c ON s.item_sk = c.item_sk
    FULL OUTER JOIN web_agg w ON COALESCE(s.item_sk, c.item_sk) = w.item_sk
),
returns_agg AS (
    SELECT item_sk,
           SUM(total_net_loss) AS total_return_loss
    FROM (
        SELECT sr_item_sk AS item_sk,
               SUM(sr_net_loss) AS total_net_loss
        FROM store_returns sr
        JOIN date_2001 d ON sr.sr_returned_date_sk = d.d_date_sk
        GROUP BY sr_item_sk
        UNION ALL
        SELECT cr_item_sk AS item_sk,
               SUM(cr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN date_2001 d ON cr.cr_returned_date_sk = d.d_date_sk
        GROUP BY cr_item_sk
        UNION ALL
        SELECT wr_item_sk AS item_sk,
               SUM(wr_net_loss) AS total_net_loss
        FROM web_returns wr
        JOIN date_2001 d ON wr.wr_returned_date_sk = d.d_date_sk
        GROUP BY wr_item_sk
    ) t
    GROUP BY item_sk
),
items_in_both AS (
    SELECT item_sk FROM store_agg
    INTERSECT
    SELECT item_sk FROM web_agg
),
item_extended AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_current_price,
           i.i_color,
           i.i_brand,
           i.i_class,
           COALESCE(sc.store_net_profit, 0) AS store_net_profit,
           COALESCE(sc.catalog_net_profit, 0) AS catalog_net_profit,
           COALESCE(sc.web_net_profit, 0) AS web_net_profit,
           COALESCE(sc.store_qty, 0) + COALESCE(sc.catalog_qty, 0) + COALESCE(sc.web_qty, 0) AS total_qty,
           COALESCE(sc.store_txn, 0) + COALESCE(sc.catalog_txn, 0) + COALESCE(sc.web_txn, 0) AS total_txn,
           COALESCE(r.total_return_loss, 0) AS total_return_loss,
           CASE 
               WHEN i.i_current_price < 20 THEN 'Low'
               WHEN i.i_current_price < 100 THEN 'Medium'
               ELSE 'High'
           END AS price_category,
           CONCAT(i.i_brand, '-', i.i_class) AS brand_class,
           COALESCE(i.i_manager_id, -1) AS manager_id,
           (SELECT MAX(ss_net_profit) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk) AS max_store_profit,
           (SELECT MAX(cs_net_profit) FROM catalog_sales cs WHERE cs.cs_item_sk = i.i_item_sk) AS max_catalog_profit,
           (SELECT MAX(ws_net_profit) FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk) AS max_web_profit,
           GREATEST(
               COALESCE((SELECT MAX(ss_net_profit) FROM store_sales ss WHERE ss.ss_item_sk = i.i_item_sk), 0),
               COALESCE((SELECT MAX(cs_net_profit) FROM catalog_sales cs WHERE cs.cs_item_sk = i.i_item_sk), 0),
               COALESCE((SELECT MAX(ws_net_profit) FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk), 0)
           ) AS max_transaction_profit
    FROM item i
    LEFT JOIN sales_combined sc ON i.i_item_sk = sc.item_sk
    LEFT JOIN returns_agg r ON i.i_item_sk = r.item_sk
    WHERE i.i_item_sk IN (SELECT item_sk FROM items_in_both)
      AND i.i_current_price IS NOT NULL
),
final_calc AS (
    SELECT *,
           (store_net_profit + catalog_net_profit + web_net_profit - total_return_loss) AS net_profit_total,
           ROW_NUMBER() OVER (ORDER BY (store_net_profit + catalog_net_profit + web_net_profit - total_return_loss) DESC) AS profit_rank,
           SUM(store_net_profit + catalog_net_profit + web_net_profit - total_return_loss) OVER () AS grand_total_profit,
           (store_net_profit + catalog_net_profit + web_net_profit - total_return_loss) /
               SUM(store_net_profit + catalog_net_profit + web_net_profit - total_return_loss) OVER () AS profit_pct,
           CASE WHEN total_return_loss > 0 THEN 'HasReturn' ELSE 'NoReturn' END AS return_flag
    FROM item_extended
)
SELECT i_item_sk,
       i_item_id,
       i_product_name,
       price_category,
       brand_class,
       manager_id,
       total_qty,
       total_txn,
       net_profit_total,
       profit_pct,
       profit_rank,
       return_flag,
       max_transaction_profit,
       CASE WHEN i_color IS NULL THEN 'UNKNOWN' ELSE i_color END AS item_color,
       CONCAT('Profit_', CAST(profit_rank AS VARCHAR)) AS profit_tag
FROM final_calc
WHERE net_profit_total > 1000
  AND price_category IN ('Medium','High')
  AND (i_color IS NULL OR i_color NOT LIKE 'X%')
  AND (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_item_sk = i_item_sk) >= 10
ORDER BY profit_rank
LIMIT 100
