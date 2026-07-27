WITH sales_returns AS (
    SELECT
        ss.ss_item_sk,
        i.i_category,
        i.i_brand,
        i.i_manufact_id,
        c.c_customer_sk,
        c.c_birth_month,
        cc.cc_call_center_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_qty,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
        COALESCE(COUNT(DISTINCT cr.cr_order_number), 0) AS return_transactions
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_units = 'Each'
      AND c.c_birth_month IN (3, 4, 11)
      AND c.c_birth_day BETWEEN 10 AND 26
      AND i.i_manufact_id IN (117, 26, 479)
      AND cc.cc_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451910 AND 2451915
      AND ss.ss_quantity > 1
    GROUP BY ss.ss_item_sk,
             i.i_category,
             i.i_brand,
             i.i_manufact_id,
             c.c_customer_sk,
             c.c_birth_month,
             cc.cc_call_center_id
)
SELECT
    i_category,
    i_brand,
    SUM(total_sales) AS category_brand_sales,
    AVG(total_profit) AS avg_profit_per_item,
    SUM(total_return_amount) AS total_returns,
    COUNT(*) AS num_items
FROM sales_returns
GROUP BY i_category, i_brand
HAVING SUM(total_sales) > 10000
ORDER BY category_brand_sales DESC
LIMIT 20
