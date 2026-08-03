WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_promo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        AVG(ws_quantity) AS avg_qty,
        MAX(ws_coupon_amt) AS max_coupon
    FROM web_sales
    WHERE ws_coupon_amt > 0
      AND ws_list_price BETWEEN 50 AND 200
      AND ws_ext_tax < 250
      AND ws_ext_discount_amt >= 0
      AND ws_quantity >= 1
      AND ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY ws_warehouse_sk, ws_promo_sk
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    p.p_promo_name,
    ws_agg.total_sales,
    ws_agg.total_profit,
    ws_agg.order_cnt,
    CASE WHEN ws_agg.total_profit > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS profit_flag,
    (
        SELECT COUNT(*)
        FROM web_sales ws_sub
        WHERE ws_sub.ws_warehouse_sk = w.w_warehouse_sk
          AND ws_sub.ws_promo_sk = p.p_promo_sk
    ) AS related_order_cnt,
    unnest_arr.value AS metric_value
FROM ws_agg
JOIN warehouse w ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
CROSS JOIN UNNEST(array[ws_agg.total_sales, ws_agg.total_profit]) AS unnest_arr(value)
WHERE p.p_channel_email = 'N'
  AND p.p_channel_catalog = 'N'
  AND w.w_zip = '64593'
  AND w.w_state = 'TX'
  AND w.w_gmt_offset = -6.00
  AND p.p_discount_active = 'Y'
ORDER BY ws_agg.total_sales DESC
LIMIT 100
