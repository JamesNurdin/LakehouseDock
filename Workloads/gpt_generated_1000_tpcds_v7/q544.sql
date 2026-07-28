WITH filtered_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_item_sk,
        wr_refunded_addr_sk,
        wr_returning_addr_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_net_loss,
        wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt > 0
)
SELECT
    d.d_date,
    i.i_category,
    i.i_brand,
    s.s_store_name,
    ca_ref.ca_city AS refunded_city,
    ca_ret.ca_city AS returning_city,
    SUM(fr.wr_return_amt) AS total_return_amount,
    SUM(fr.wr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(fr.wr_net_loss) DESC) AS category_net_loss_rank,
    CASE
        WHEN SUM(fr.wr_return_amt) > 10000 THEN 'High'
        WHEN SUM(fr.wr_return_amt) > 5000  THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_level
FROM filtered_returns fr
JOIN date_dim d        ON fr.wr_returned_date_sk   = d.d_date_sk
JOIN item i            ON fr.wr_item_sk           = i.i_item_sk
JOIN customer_address ca_ref ON fr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret ON fr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s           ON s.s_closed_date_sk      = d.d_date_sk
WHERE d.d_year = 2000                              -- filter on year
  AND d.d_month_seq BETWEEN 1200 AND 1220          -- filter on month sequence range
  AND i.i_category_id IN (2, 5, 9)                 -- specific categories
  AND i.i_brand_id = 1004002                       -- a single brand
  AND s.s_state = 'CA'                             -- stores in California
  AND s.s_zip LIKE '55%'                           -- ZIP code pattern
GROUP BY
    d.d_date,
    i.i_category,
    i.i_brand,
    s.s_store_name,
    ca_ref.ca_city,
    ca_ret.ca_city
ORDER BY total_net_loss DESC
LIMIT 100
