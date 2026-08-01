WITH sampled_customers AS (
  SELECT *
  FROM customer TABLESAMPLE BERNOULLI (10)
),
returns_joined AS (
  SELECT
    wr.wr_order_number,
    wr.wr_return_amt,
    wr.wr_reversed_charge,
    wr.wr_return_quantity,
    wp.wp_web_page_id,
    wp.wp_type,
    wp.wp_autogen_flag,
    c_ret.c_customer_id                                   AS returning_customer_id,
    c_ret.c_first_name                                   AS returning_first_name,
    c_ret.c_last_name                                    AS returning_last_name,
    c_page.c_customer_id                                 AS page_owner_customer_id,
    c_page.c_first_name                                  AS page_owner_first_name,
    c_page.c_last_name                                   AS page_owner_last_name
  FROM web_returns wr
  JOIN sampled_customers c_ret
    ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN sampled_customers c_page
    ON wp.wp_customer_sk = c_page.c_customer_sk
  WHERE wp.wp_autogen_flag = 'N'
    AND wp.wp_access_date_sk BETWEEN 2452630 AND 2452650
    AND c_ret.c_current_cdemo_sk > 500000
    AND wr.wr_reversed_charge > 50
    AND wr.wr_return_amt > 100
),
ranked_returns AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY returning_customer_id ORDER BY wr_return_amt DESC) AS rn_return_amt,
    RANK()       OVER (PARTITION BY returning_customer_id ORDER BY wr_return_quantity DESC) AS rnk_quantity
  FROM returns_joined
),
first_set AS (
  SELECT
    returning_customer_id,
    returning_first_name,
    returning_last_name,
    wr_order_number,
    wr_return_amt,
    rnk_quantity,
    rn_return_amt
  FROM ranked_returns
  WHERE rnk_quantity = 1
    AND rn_return_amt <= 5
),
second_set AS (
  SELECT
    page_owner_customer_id   AS returning_customer_id,
    page_owner_first_name    AS returning_first_name,
    page_owner_last_name     AS returning_last_name,
    wr_order_number,
    wr_return_amt,
    rnk_quantity,
    rn_return_amt
  FROM ranked_returns
  WHERE wr_return_amt > 500
    AND rnk_quantity = 1
)
SELECT
  returning_customer_id,
  returning_first_name,
  returning_last_name,
  wr_order_number,
  wr_return_amt,
  rnk_quantity,
  rn_return_amt
FROM (
  SELECT * FROM first_set
  UNION ALL
  SELECT * FROM second_set
) AS combined
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr2
  WHERE wr2.wr_order_number = combined.wr_order_number
    AND wr2.wr_return_amt > combined.wr_return_amt
)
ORDER BY wr_return_amt DESC, returning_customer_id
LIMIT 100
