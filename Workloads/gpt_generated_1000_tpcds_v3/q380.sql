WITH returns_agg AS (
    SELECT
        wr_item_sk,
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 10.00
      AND wr_return_quantity > 0
      AND wr_return_ship_cost > 20.00
      AND wr_account_credit < 500.00
      AND wr_fee BETWEEN 0 AND 50.00
    GROUP BY wr_item_sk, wr_order_number
),

distinct_promos AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_discount_active,
        p.p_item_sk
    FROM promotion p
    WHERE p.p_channel_dmail = 'Y'
      AND p.p_discount_active = 'Y'
      AND p.p_channel_event = 'N'
      AND p.p_channel_email = 'N'
      AND p.p_channel_tv = 'N'
)
SELECT
    i.i_brand,
    i.i_category,
    dp.p_promo_name,
    CASE
        WHEN dp.p_discount_active = 'Y' AND dp.p_channel_dmail = 'Y' THEN 'Active DMail Promo'
        ELSE 'Other Promo'
    END AS promo_type,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ra.total_return_amt) AS total_return_amount,
    SUM(ra.total_return_qty) AS total_return_quantity,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    MIN(ws.ws_list_price) AS min_list_price,
    MAX(ws.ws_list_price) AS max_list_price
FROM item i
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN distinct_promos dp ON ws.ws_promo_sk = dp.p_promo_sk
    AND dp.p_item_sk = i.i_item_sk
JOIN returns_agg ra ON ra.wr_item_sk = ws.ws_item_sk
    AND ra.wr_order_number = ws.ws_order_number
WHERE i.i_current_price > 50.00
  AND i.i_brand = 'Brand#45'
  AND i.i_category = 'Electronics'
  AND ws.ws_list_price BETWEEN 100.00 AND 200.00
  AND ws.ws_quantity >= 2
  AND ws.ws_net_paid_inc_ship_tax > 1000.00
GROUP BY
    i.i_brand,
    i.i_category,
    dp.p_promo_name,
    CASE
        WHEN dp.p_discount_active = 'Y' AND dp.p_channel_dmail = 'Y' THEN 'Active DMail Promo'
        ELSE 'Other Promo'
    END
ORDER BY total_net_profit DESC
LIMIT 100
