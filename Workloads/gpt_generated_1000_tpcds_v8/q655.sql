WITH inv_dates AS (
   SELECT DISTINCT inv_date_sk
   FROM inventory
   WHERE inv_quantity_on_hand > 0
),
site_open_dates AS (
   SELECT DISTINCT web_open_date_sk AS date_sk
   FROM web_site
   WHERE web_state = 'CA'
),
dates_only_inventory AS (
   SELECT inv_date_sk FROM inv_dates
   EXCEPT
   SELECT date_sk FROM site_open_dates
),
dates_both AS (
   SELECT inv_date_sk FROM inv_dates
   INTERSECT
   SELECT date_sk FROM site_open_dates
),
inv_date AS (
   SELECT i.inv_date_sk,
          i.inv_item_sk,
          i.inv_warehouse_sk,
          i.inv_quantity_on_hand,
          d.d_date,
          d.d_year,
          d.d_month_seq,
          d.d_day_name
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
   WHERE i.inv_quantity_on_hand > 0
     AND d.d_year = 2022
     AND d.d_month_seq BETWEEN 1 AND 12
),
site_date AS (
   SELECT w.web_site_sk,
          w.web_site_id,
          w.web_name,
          w.web_open_date_sk,
          w.web_close_date_sk,
          d_open.d_date AS open_date,
          d_close.d_date AS close_date,
          w.web_class,
          w.web_state
   FROM web_site w
   LEFT JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
   LEFT JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
   WHERE w.web_state = 'CA'
     AND w.web_class IS NOT NULL
)
SELECT
    COALESCE(i.inv_date_sk, s.web_open_date_sk) AS date_sk,
    i.inv_item_sk,
    i.inv_warehouse_sk,
    i.inv_quantity_on_hand,
    s.web_site_sk,
    s.web_site_id,
    s.web_name,
    s.web_state,
    (SELECT SUM(ii.inv_quantity_on_hand)
       FROM inventory ii
       WHERE ii.inv_date_sk = COALESCE(i.inv_date_sk, s.web_open_date_sk)
    ) AS total_qty_on_date,
    SUM(i.inv_quantity_on_hand) OVER (
        PARTITION BY COALESCE(i.inv_date_sk, s.web_open_date_sk)
        ORDER BY i.inv_item_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_qty,
    RANK() OVER (
        PARTITION BY COALESCE(i.inv_date_sk, s.web_open_date_sk)
        ORDER BY i.inv_quantity_on_hand DESC
    ) AS qty_rank,
    CASE 
        WHEN i.inv_quantity_on_hand IS NULL THEN 'No Inventory'
        WHEN s.web_site_sk IS NULL THEN 'No Site'
        ELSE 'Both Present'
    END AS presence_flag,
    CASE WHEN dio.inv_date_sk IS NOT NULL THEN 'Only Inventory' END AS only_inventory_flag
FROM inv_date i
FULL OUTER JOIN site_date s
  ON i.inv_date_sk = s.web_open_date_sk
LEFT JOIN dates_only_inventory dio
  ON COALESCE(i.inv_date_sk, s.web_open_date_sk) = dio.inv_date_sk
WHERE (i.inv_quantity_on_hand IS NULL OR i.inv_quantity_on_hand > 5)
  AND (s.web_state = 'CA' OR s.web_state IS NULL)
  AND (i.d_year = 2022 OR i.d_year IS NULL)
  AND COALESCE(i.inv_date_sk, s.web_open_date_sk) IN (SELECT inv_date_sk FROM dates_both)
ORDER BY date_sk, qty_rank
LIMIT 100
