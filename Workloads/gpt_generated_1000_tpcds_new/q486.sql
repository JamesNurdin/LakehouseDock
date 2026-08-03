WITH
    inv_agg AS (
        SELECT inv_date_sk,
               sum(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_date_sk
    ),
    sampled_returns AS (
        SELECT *
        FROM web_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    promo_agg AS (
        SELECT p_promo_sk,
               sum(p_cost) AS total_cost,
               count(*) AS promo_cnt
        FROM promotion
        GROUP BY p_promo_sk
    ),
    union_refunds AS (
        SELECT DISTINCT wr.wr_refunded_customer_sk AS cust_sk,
               SUM(wr.wr_return_amt) AS refund_amt
        FROM sampled_returns wr
        GROUP BY wr.wr_refunded_customer_sk
        UNION
        SELECT DISTINCT wr.wr_returning_customer_sk AS cust_sk,
               SUM(wr.wr_return_amt) AS refund_amt
        FROM sampled_returns wr
        GROUP BY wr.wr_returning_customer_sk
    ),
    intersect_cust AS (
        SELECT c.c_customer_sk
        FROM customer c
        WHERE c.c_birth_month = 5
        INTERSECT
        SELECT DISTINCT wr.wr_refunded_customer_sk
        FROM sampled_returns wr
        WHERE wr.wr_return_amt > 100
    )
SELECT DISTINCT
    c_ref.c_customer_id,
    c_ref.c_birth_day,
    CASE
        WHEN c_ref.c_preferred_cust_flag = 'Y' THEN 'Preferred'
        ELSE 'Regular'
    END AS customer_type,
    d_ret.d_year,
    d_ret.d_month_seq,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    (
        SELECT SUM(i.total_qty)
        FROM inv_agg i
        JOIN date_dim d2 ON i.inv_date_sk = d2.d_date_sk
        WHERE d2.d_year = d_ret.d_year
    ) AS year_inventory_qty,
    pa.total_cost,
    val.metric,
    val.amount
FROM sampled_returns wr
JOIN date_dim d_ret               ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_ref               ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN customer c_ret               ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
JOIN web_page wp1                ON wr.wr_web_page_sk = wp1.wp_web_page_sk
JOIN date_dim d_creation          ON wp1.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_first_sales       ON c_ref.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN inv_agg inv                  ON inv.inv_date_sk = d_ret.d_date_sk
JOIN promotion p_start            ON p_start.p_start_date_sk = d_ret.d_date_sk
JOIN promotion p_end              ON p_end.p_end_date_sk = d_ret.d_date_sk
JOIN promo_agg pa                 ON pa.p_promo_sk = p_start.p_promo_sk
JOIN union_refunds ur             ON ur.cust_sk = c_ref.c_customer_sk
JOIN intersect_cust ic            ON ic.c_customer_sk = c_ref.c_customer_sk
LEFT JOIN LATERAL (
    SELECT metric, amount
    FROM UNNEST(
        ARRAY[
            ROW('return_qty', CAST(wr.wr_return_quantity AS double)),
            ROW('return_amount', wr.wr_return_amt)
        ]
    ) AS t(metric, amount)
) AS val ON TRUE
WHERE d_ret.d_year = 2022
GROUP BY
    c_ref.c_customer_id,
    c_ref.c_birth_day,
    c_ref.c_preferred_cust_flag,
    d_ret.d_year,
    d_ret.d_month_seq,
    pa.total_cost,
    val.metric,
    val.amount
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
