-- Goal: Analyze profitability of stores for premium products, filtering by city and address, ensuring the items have no associated web returns, and compute the average profit per item across all stores.
WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_addr_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ca.ca_suite_number,
        i.i_category,
        i.i_product_name,
        -- derived string columns
        regexp_extract(i.i_product_name, '(.*)Premium(.*)', 1) AS prod_prefix,
        concat(s.s_city, ', ', s.s_state) AS store_location
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, 'Premium')
      AND s.s_city LIKE 'A%'
      AND concat(ca.ca_suite_number, '') LIKE '%Suite%'
      -- anti‑join: exclude rows that have a matching web return for the same item and address
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
          WHERE ws.ws_item_sk = ss.ss_item_sk
            AND ws.ws_bill_addr_sk = ss.ss_addr_sk
      )
      -- at least one other sale for the same store with quantity > 5
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_store_sk = s.s_store_sk
            AND ss2.ss_quantity > 5
      )
)
SELECT
    s_store_id,
    s_store_name,
    i_category,
    SUM(ss_net_profit) AS total_store_profit,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    -- correlated scalar subquery: average profit for this item across all stores
    (SELECT avg(ss_inner.ss_net_profit)
     FROM store_sales ss_inner
     WHERE ss_inner.ss_item_sk = fs.ss_item_sk) AS avg_item_profit,
    prod_prefix,
    store_location
FROM filtered_sales fs
GROUP BY
    s_store_id,
    s_store_name,
    i_category,
    i_product_name,
    prod_prefix,
    store_location,
    ss_item_sk
HAVING SUM(ss_net_profit) > 0
ORDER BY total_store_profit DESC
LIMIT 100
