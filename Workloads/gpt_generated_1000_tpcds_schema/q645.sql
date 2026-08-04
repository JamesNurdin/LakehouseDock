WITH
    sampled_returns AS (
        SELECT *
        FROM catalog_returns
        TABLESAMPLE BERNOULLI (10)
        WHERE cr_return_amount > 100
          AND cr_return_tax < 50
          AND cr_return_quantity > 0
          AND cr_store_credit BETWEEN 0 AND 200
          AND cr_reversed_charge > 20
          AND cr_return_amt_inc_tax > 500
    ),
    agg_returns AS (
        SELECT cr_refunded_addr_sk,
               SUM(cr_return_amount) AS total_return_amount,
               SUM(cr_return_tax) AS total_return_tax,
               SUM(cr_net_loss) AS total_net_loss,
               COUNT(*) AS cnt_returns
        FROM sampled_returns
        GROUP BY cr_refunded_addr_sk
    ),
    sampled_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (5)
        WHERE ss_ext_sales_price > 1000
          AND ss_coupon_amt < 200
          AND ss_list_price > 80
          AND ss_quantity > 1
          AND ss_net_profit > 0
          AND ss_ext_wholesale_cost > 500
    ),
    agg_sales AS (
        SELECT ss_addr_sk,
               SUM(ss_ext_sales_price) AS total_sales,
               SUM(ss_net_profit) AS total_profit,
               COUNT(*) AS cnt_sales
        FROM sampled_sales
        GROUP BY ss_addr_sk
    )
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    r.total_return_amount,
    s.total_sales,
    (r.total_return_amount + s.total_sales) AS combined_sales_return,
    CASE
        WHEN r.total_net_loss > 1000 THEN 'High Loss'
        WHEN r.total_net_loss > 500 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    RANK() OVER (ORDER BY (r.total_net_loss + s.total_profit) DESC) AS loss_profit_rank
FROM agg_returns r
JOIN customer_address ca
    ON r.cr_refunded_addr_sk = ca.ca_address_sk
JOIN agg_sales s
    ON s.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_city IN ('Spring', 'Elm')
  AND ca.ca_suite_number LIKE 'Suite %'
  AND ca.ca_zip LIKE '9%'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_addr_sk = ca.ca_address_sk
          AND cr2.cr_reason_sk = 99
    )
  AND (SELECT AVG(ss_net_profit) FROM store_sales) > 0
ORDER BY loss_profit_rank
OFFSET 0 FETCH NEXT 100 ROWS ONLY
