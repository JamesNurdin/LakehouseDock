/*
Goal: Identify the highest‑loss customers who had catalog returns from a specific warehouse and whose address is a single‑family home in selected cities, ranking each customer's combined catalog and web net loss and showing city‑level total loss, while excluding any customer with a very large web loss.
*/
WITH catalog AS (
    SELECT
        cr_order_number,
        cr_refunded_customer_sk,
        cr_refunded_addr_sk,
        cr_return_amount,
        cr_net_loss,
        cr_warehouse_sk,
        cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_warehouse_sk = 19                         -- predicate 1
      AND cr_return_amount BETWEEN 150 AND 1000      -- predicate 2
),
web AS (
    SELECT
        wr_order_number,
        wr_refunded_customer_sk,
        wr_return_amt,
        wr_net_loss,
        wr_return_tax,
        wr_returned_date_sk
    FROM web_returns
    WHERE wr_return_tax > 20                         -- predicate 3
      AND wr_returned_date_sk BETWEEN 2450000 AND 2452000  -- predicate 4 (surrogate date range)
)
SELECT
    c.cr_order_number,
    c.cr_return_amount,
    c.cr_net_loss,
    w.wr_return_amt,
    w.wr_net_loss,
    ca.ca_city,
    ca.ca_location_type,
    RANK() OVER (
        PARTITION BY c.cr_refunded_customer_sk
        ORDER BY (c.cr_net_loss + w.wr_net_loss) DESC
    ) AS loss_rank,
    SUM(c.cr_net_loss + w.wr_net_loss) OVER (PARTITION BY ca.ca_city) AS city_total_loss
FROM catalog c
JOIN customer cu
    ON c.cr_refunded_customer_sk = cu.c_customer_sk
JOIN customer_address ca
    ON c.cr_refunded_addr_sk = ca.ca_address_sk
JOIN web w
    ON w.wr_refunded_customer_sk = cu.c_customer_sk
WHERE ca.ca_location_type = 'single family'                -- predicate 5
  AND ca.ca_city IN ('Lakeview', 'Maple Grove')            -- predicate 6
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = cu.c_customer_sk
          AND wr2.wr_net_loss > 5000
    )
ORDER BY loss_rank ASC, c.cr_order_number
LIMIT 100
