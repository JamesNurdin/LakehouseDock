WITH filtered_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_store_credit,
        cr.cr_fee,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_reason_sk
    FROM catalog_returns cr
    WHERE cr.cr_store_credit > 100
      AND cr.cr_fee > 20
      AND cr.cr_net_loss IS NOT NULL
),
filtered_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_coupon_amt,
        ws.ws_order_number,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_coupon_amt > 1000
),
joined_data AS (
    SELECT
        i.i_category,
        i.i_category_id,
        i.i_size,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number AS cr_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_order_number AS ws_order_number,
        r.r_reason_desc
    FROM filtered_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN filtered_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (4, 9)
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = cr.cr_item_sk
            AND ws2.ws_coupon_amt > 5000
      )
)
SELECT
    i_category,
    i_category_id,
    i_size,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_ext_sales_price) AS total_sales_amount,
    COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
    AVG(ws_ext_discount_amt) AS avg_discount_amount,
    CASE
        WHEN SUM(cr_net_loss) > 5000 THEN 'HighLoss'
        ELSE 'LowLoss'
    END AS loss_category
FROM joined_data
GROUP BY i_category, i_category_id, i_size
ORDER BY total_return_amount DESC
LIMIT 100
