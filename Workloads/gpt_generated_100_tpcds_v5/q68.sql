WITH filtered_promos AS (
    SELECT p_promo_sk, p_promo_id, p_channel_email, p_item_sk
    FROM promotion
    WHERE p_channel_email = 'N'
      AND p_item_sk IN (204688, 292022, 60304)
      AND p_discount_active = 'Y'
)
SELECT
    fp.p_promo_id,
    fp.p_channel_email,
    CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COUNT(wr.wr_return_quantity) AS return_rows
FROM filtered_promos fp
LEFT JOIN web_sales ws
    ON ws.ws_promo_sk = fp.p_promo_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE ws.ws_ext_sales_price > 500
  AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451920
  AND ws.ws_quantity >= 1
  AND (SELECT COUNT(*) FROM web_returns r WHERE r.wr_order_number = ws.ws_order_number) > 0
  AND fp.p_promo_id NOT IN (SELECT p_promo_id FROM promotion WHERE p_channel_tv = 'Y')
GROUP BY fp.p_promo_id, fp.p_channel_email
ORDER BY total_sales DESC
LIMIT 100
