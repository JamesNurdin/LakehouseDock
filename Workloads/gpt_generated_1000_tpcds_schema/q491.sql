WITH
sampled_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_cdemo_sk,
        cr.cr_refunded_hdemo_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_returning_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_returning_addr_sk,
        cr.cr_call_center_sk,
        cr.cr_catalog_page_sk,
        cr.cr_ship_mode_sk,
        cr.cr_warehouse_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_amt_inc_tax,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_refunded_cash,
        cr.cr_reversed_charge,
        cr.cr_store_credit,
        cr.cr_net_loss,
        cp.cp_description,
        r.r_reason_desc,
        c.c_customer_id,
        ca.ca_county
    FROM catalog_returns cr
    TABLESAMPLE BERNOULLI (10)
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(r.r_reason_desc, '^Did not')
      AND ca.ca_county LIKE '%County'
),
words_exploded AS (
    SELECT
        cr_refunded_customer_sk AS customer_sk,
        cr_return_amount,
        regexp_extract(cp_description, '(\\w+)', 1) AS first_word,
        CASE WHEN cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_size,
        word
    FROM sampled_returns
    CROSS JOIN UNNEST(split(cp_description, ' ')) AS t(word)
),
agg_returns AS (
    SELECT
        customer_sk,
        COUNT(*) AS num_returns,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT first_word) AS distinct_first_words,
        SUM(CASE WHEN return_size = 'High' THEN 1 ELSE 0 END) AS high_return_cnt
    FROM words_exploded
    GROUP BY customer_sk
),
high_value_customers AS (
    SELECT customer_sk
    FROM agg_returns
    WHERE total_return_amount > 500
)
SELECT
    we.customer_sk,
    we.word,
    we.return_size,
    we.first_word,
    we.cr_return_amount
FROM words_exploded we
WHERE we.customer_sk IN (
    SELECT customer_sk FROM agg_returns
    EXCEPT
    SELECT customer_sk FROM high_value_customers
)
ORDER BY we.cr_return_amount DESC
LIMIT 100
