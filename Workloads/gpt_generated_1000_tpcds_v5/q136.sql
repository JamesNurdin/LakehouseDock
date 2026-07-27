/*
Goal: Identify top‑selling customers and items by total web sales amount, enriched with return information, filtered to a specific time shift and minute, high coupon usage, and modest return quantities. The query joins all six TPC‑DS tables, uses a CTE for the base join, aggregates key metrics, applies a CASE expression to label profit categories, adds a ROW_NUMBER window function to rank sales within each profit category, and orders the final result by total sales.
*/
WITH sales_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        i.i_item_sk,
        i.i_product_name,
        t.t_hour,
        t.t_shift,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM customer c
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_customer_sk = c.c_customer_sk
    WHERE t.t_shift = 'second'
      AND t.t_minute = 12
      AND ws.ws_coupon_amt > 500
      AND sr.sr_return_quantity <= 20
),
agg AS (
    SELECT
        c_customer_id,
        i_product_name,
        profit_category,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(sr_return_amt) AS avg_return_amount,
        COUNT(DISTINCT c_customer_sk) AS distinct_customers,
        MIN(ws_net_profit) AS min_profit,
        MAX(ws_net_profit) AS max_profit
    FROM sales_returns
    GROUP BY c_customer_id, i_product_name, profit_category
)
SELECT
    c_customer_id,
    i_product_name,
    profit_category,
    total_sales,
    avg_return_amount,
    distinct_customers,
    min_profit,
    max_profit,
    ROW_NUMBER() OVER (PARTITION BY profit_category ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
