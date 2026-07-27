WITH ss_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_store_qty,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_customer_sk) AS store_customer_cnt
    FROM store_sales
    WHERE ss_coupon_amt > 30
      AND ss_hdemo_sk = 1511
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_brand,
    i.i_category,
    w.w_warehouse_name,
    w.w_street_type,
    SUM(ss_agg.total_store_qty) AS total_store_qty,
    SUM(ss_agg.total_store_sales) AS total_store_sales,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
FROM ss_agg
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_net_profit > 0
  AND w.w_street_type = 'Avenue'
  AND ws.ws_ship_cdemo_sk = 483439
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_coupon_amt > 100
        LIMIT 1
    )
GROUP BY
    i.i_item_id,
    i.i_brand,
    i.i_category,
    w.w_warehouse_name,
    w.w_street_type
ORDER BY total_store_sales DESC
LIMIT 100
