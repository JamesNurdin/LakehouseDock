/* goal: Identify the top states and quarters by combined sales and return amounts for the year 2001, showing only the three highest‑return rows per state */
WITH base_join AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_addr_sk,
        ss.ss_item_sk,
        ss.ss_ext_sales_price,
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_fee,
        d.d_year,
        d.d_quarter_name,
        ca.ca_state,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                                 -- filter 1: specific year
      AND cr.cr_fee > 20.00                               -- filter 2: fee threshold
      AND ss.ss_ext_sales_price > 1000.00                -- filter 3: high sales price
      AND ss.ss_item_sk IN (
            SELECT DISTINCT inv_item_sk
            FROM inventory
            WHERE inv_quantity_on_hand > 500          -- uncorrelated IN sub‑query
        )
),
ranked AS (
    SELECT
        ca_state AS state,
        d_quarter_name AS quarter,
        ss_ext_sales_price AS sales_amount,
        cr_return_amount AS return_amount,
        ss_ticket_number AS order_id,
        cr_fee AS fee,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY cr_return_amount DESC) AS rn
    FROM base_join
)
SELECT
    state,
    quarter,
    SUM(sales_amount) AS total_sales,
    SUM(return_amount) AS total_returns,
    COUNT(DISTINCT order_id) AS distinct_orders,
    AVG(fee) AS avg_fee
FROM ranked
WHERE rn <= 3                               -- top‑k (k=3) per state
GROUP BY state, quarter
HAVING SUM(return_amount) > 1000               -- filter groups with sufficient returns
ORDER BY total_returns DESC
LIMIT 100
