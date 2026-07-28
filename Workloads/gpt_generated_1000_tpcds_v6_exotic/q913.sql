WITH item_lookup AS (
    SELECT i_item_sk,
           i_item_id,
           i_brand,
           i_category
    FROM item
    WHERE i_current_price > 0
)
SELECT
    il.i_item_id,
    td.t_hour,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Positive' ELSE 'Non-Positive' END AS profit_category,
    'WEB_SALE' AS source
FROM web_sales ws
JOIN item_lookup il ON ws.ws_item_sk = il.i_item_sk
JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_code = 'AIR'
  AND td.t_hour BETWEEN 8 AND 20
GROUP BY il.i_item_id, td.t_hour

UNION ALL

SELECT
    il.i_item_id,
    td.t_hour,
    -SUM(sr.sr_return_amt) AS total_sales,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'NoLoss' END AS profit_category,
    'STORE_RETURN' AS source
FROM store_returns sr
JOIN item_lookup il ON sr.sr_item_sk = il.i_item_sk
JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
WHERE td.t_sub_shift = 'evening'
GROUP BY il.i_item_id, td.t_hour

ORDER BY total_sales DESC
LIMIT 100
