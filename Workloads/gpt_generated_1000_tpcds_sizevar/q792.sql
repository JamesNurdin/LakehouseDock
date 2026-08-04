WITH sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
),
store_sales_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_addr_sk,
        SUM(ss_net_paid) AS total_store_net_paid,
        COUNT(*) AS cnt_store_sales
    FROM sampled_store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_sold_date_sk, ss_sold_time_sk, ss_addr_sk
),
web_sales_agg AS (
    SELECT
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS total_web_net_paid,
        COUNT(*) AS cnt_web_sales
    FROM web_sales
    WHERE ws_quantity > 1
    GROUP BY ws_sold_date_sk, ws_sold_time_sk, ws_bill_addr_sk
),
returns_filtered AS (
    SELECT
        cr_returned_time_sk,
        cr_returning_addr_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_reason_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 1
      AND cr_return_amount > 20
),
intersect_addresses AS (
    SELECT ss_addr_sk AS address_sk
    FROM store_sales_agg
    WHERE total_store_net_paid > 100
    INTERSECT
    SELECT ws_bill_addr_sk
    FROM web_sales_agg
    WHERE total_web_net_paid > 100
),
union_sales AS (
    SELECT ss_addr_sk AS address_sk, total_store_net_paid AS total_paid
    FROM store_sales_agg
    UNION
    SELECT ws_bill_addr_sk, total_web_net_paid
    FROM web_sales_agg
),
combined_sales AS (
    SELECT
        address_sk,
        SUM(total_paid) AS combined_total_paid,
        COUNT(*) AS source_count
    FROM union_sales
    GROUP BY address_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    cs.combined_total_paid,
    CASE WHEN cs.combined_total_paid > 1000 THEN 'High' ELSE 'Low' END AS payment_category,
    r.r_reason_desc,
    t_ret.t_hour,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY cs.combined_total_paid DESC) AS state_rank
FROM combined_sales cs
JOIN intersect_addresses ia
    ON cs.address_sk = ia.address_sk
JOIN customer_address ca
    ON cs.address_sk = ca.ca_address_sk
JOIN returns_filtered rf
    ON cs.address_sk = rf.cr_returning_addr_sk
JOIN reason r
    ON rf.cr_reason_sk = r.r_reason_sk
JOIN time_dim t_ret
    ON rf.cr_returned_time_sk = t_ret.t_time_sk
ORDER BY cs.combined_total_paid DESC, ca.ca_city
LIMIT 100
