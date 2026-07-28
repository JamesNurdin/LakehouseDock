/* goal: Analyze net sales performance by item category/brand and customer state, while limiting to items that had catalog and web returns meeting specific criteria. */
WITH filtered_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_addr_sk,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        ss.ss_wholesale_cost,
        ss.ss_ext_discount_amt
    FROM store_sales ss
    WHERE ss.ss_quantity > 2                                   -- selective predicate 1
      AND ss.ss_net_paid_inc_tax BETWEEN 100 AND 1500          -- selective predicate 2
      AND ss.ss_wholesale_cost > 10.00                         -- selective predicate 3
      AND ss.ss_ext_discount_amt < 50.00                       -- selective predicate 4
)
SELECT
    i.i_category,
    i.i_brand,
    ca.ca_state,
    COUNT(DISTINCT fs.ss_ticket_number) AS sales_transactions,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_net_paid_inc_tax) AS avg_net_paid,
    MIN(fs.ss_ext_sales_price) AS min_sales,
    MAX(fs.ss_ext_sales_price) AS max_sales
FROM filtered_sales fs
JOIN item i
  ON fs.ss_item_sk = i.i_item_sk
JOIN customer_address ca
  ON fs.ss_addr_sk = ca.ca_address_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = i.i_item_sk
          AND cr.cr_return_amount > 20.00                 -- return amount filter
          AND cr.cr_return_quantity = 1
          AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450200
    )
  AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_item_sk = i.i_item_sk
          AND wr.wr_fee > 30.00                           -- web return fee filter
          AND wr.wr_account_credit < 100.00
          AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2450200
    )
GROUP BY i.i_category, i.i_brand, ca.ca_state
ORDER BY total_sales DESC
LIMIT 100
