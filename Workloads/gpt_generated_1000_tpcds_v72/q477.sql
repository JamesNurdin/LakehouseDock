WITH sales_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2452000 AND 2452100
      AND i.i_wholesale_cost > 1.00
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
      AND ws.ws_ext_sales_price > 1000
      AND EXISTS (
          SELECT 1
          FROM promotion p_chk
          WHERE p_chk.p_item_sk = i.i_item_sk
            AND p_chk.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_category, c.c_customer_id
),
top_sales AS (
    SELECT c_customer_id, total_sales AS metric, 'sales' AS source
    FROM sales_data
    WHERE total_sales > 5000
),
top_returns AS (
    SELECT c_customer_id, total_return_amount AS metric, 'returns' AS source
    FROM sales_data
    WHERE total_return_amount > 1000
),
combined_top AS (
    SELECT * FROM top_sales
    UNION ALL
    SELECT * FROM top_returns
)
SELECT
    sd.i_category AS category,
    AVG(ct.metric) AS avg_metric,
    COUNT(DISTINCT sd.c_customer_id) AS num_customers,
    (SELECT COUNT(*) FROM promotion WHERE p_discount_active = 'Y') AS active_promo_count
FROM combined_top ct
JOIN sales_data sd
    ON sd.c_customer_id = ct.c_customer_id
WHERE ct.source = 'sales'
GROUP BY sd.i_category
HAVING AVG(ct.metric) > 2000
ORDER BY avg_metric DESC
LIMIT 100
