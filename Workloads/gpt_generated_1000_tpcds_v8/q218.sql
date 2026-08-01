WITH high_qty_items AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_quantity >= 20
),
discounted_items AS (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_ext_discount_amt > 0
),
common_items AS (
    SELECT ws_item_sk FROM high_qty_items
    INTERSECT
    SELECT ws_item_sk FROM discounted_items
),
max_price AS (
    SELECT MAX(ws_sales_price) AS price
    FROM web_sales
)
SELECT
    CONCAT(d.d_day_name, '_', CAST(d.d_year AS VARCHAR)) AS day_year,
    d.d_day_name,
    d.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'overall_profit'
        ELSE 'overall_loss'
    END AS profit_status
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
WHERE ws.ws_item_sk IN (SELECT ws_item_sk FROM common_items)
  AND ws.ws_sales_price > (SELECT price FROM max_price)
  AND (REGEXP_LIKE(d.d_day_name, '^S') OR d.d_holiday LIKE '%Thanksgiving%')
  AND SUBSTRING(d.d_quarter_name, 1, 2) = 'Q1'
GROUP BY
    CONCAT(d.d_day_name, '_', CAST(d.d_year AS VARCHAR)),
    d.d_day_name,
    d.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
