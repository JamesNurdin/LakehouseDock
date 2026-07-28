/* goal: Analyze net revenue and order volume by state, product category and promotion for a specific set of promotions and warehouses, filtered by recent sales dates and price range. */
WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_paid,
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_warehouse_sk
    FROM
        catalog_sales cs
    WHERE
        cs.cs_quantity > 0
)
SELECT
    w.w_state,
    i.i_category,
    p.p_promo_name,
    COUNT(DISTINCT fs.cs_order_number) AS order_count,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_quantity) AS avg_quantity,
    MIN(fs.cs_sales_price) AS min_sales_price,
    MAX(fs.cs_sales_price) AS max_sales_price
FROM
    filtered_sales fs
    JOIN customer c
        ON fs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON fs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON fs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON fs.cs_warehouse_sk = w.w_warehouse_sk
WHERE
    p.p_channel_catalog = 'N'                         -- filter 1: catalog channel not used
    AND p.p_channel_tv = 'N'                           -- filter 2: TV channel not used
    AND w.w_zip = '29231'                              -- filter 3: specific warehouse ZIP
    AND c.c_first_sales_date_sk BETWEEN 2449361 AND 2451903   -- filter 4: sales dates in a recent window
    AND i.i_current_price > 20.00                     -- filter 5: only items above $20
GROUP BY
    w.w_state,
    i.i_category,
    p.p_promo_name
ORDER BY
    total_net_paid DESC
