WITH filtered_returns AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_ship_mode_sk,
        cr.cr_refunded_cash,
        cr.cr_return_amount,
        cr.cr_returned_date_sk
    FROM catalog_returns AS cr
    WHERE cr.cr_refunded_cash > 100.00
      AND cr.cr_returned_date_sk > 2450000
), filtered_items AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_wholesale_cost,
        i.i_current_price,
        i.i_rec_start_date
    FROM item AS i
    WHERE i.i_wholesale_cost < 5.00
      AND i.i_rec_start_date >= DATE '1999-01-01'
), filtered_ship AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_carrier,
        sm.sm_type
    FROM ship_mode AS sm
    WHERE sm.sm_type = 'AIR'
)
SELECT
    i.i_category,
    sm.sm_carrier,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    MIN(i.i_current_price) AS min_current_price,
    MAX(i.i_current_price) AS max_current_price
FROM filtered_returns AS cr
INNER JOIN filtered_items AS i
    ON cr.cr_item_sk = i.i_item_sk
INNER JOIN filtered_ship AS sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN store_sales AS ss
    ON ss.ss_item_sk = i.i_item_sk
INNER JOIN customer AS c
    ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY i.i_category, sm.sm_carrier
HAVING SUM(cr.cr_return_amount) > 5000.00
ORDER BY total_return_amount DESC
LIMIT 100
