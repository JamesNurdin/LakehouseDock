WITH
-- Join the fact table to all dimension tables (star schema)
sales_join AS (
    SELECT
        cs.cs_sold_date_sk,
        d_sold.d_date,
        s.s_store_id,
        s.s_store_name,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        ca_bill.ca_state,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        ARRAY[cs.cs_quantity, cs.cs_wholesale_cost] AS qty_cost_arr
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                         -- predicate 1
      AND cc.cc_division IN (1, 2, 3, 4)               -- predicate 2
      AND cp.cp_department = 'Electronics'            -- predicate 3
      AND ca_bill.ca_state = 'CA'                     -- predicate 4
),

-- Explode the array created in the previous step
unnested_sales AS (
    SELECT
        sj.cs_sold_date_sk,
        sj.d_date,
        sj.s_store_id,
        sj.s_store_name,
        sj.cc_call_center_id,
        sj.cp_catalog_page_id,
        sj.ca_state,
        sj.cs_quantity,
        sj.cs_wholesale_cost,
        sj.cs_net_paid,
        sj.cs_ext_sales_price,
        u.val AS array_value,
        u.ordinality AS array_position
    FROM sales_join sj
    CROSS JOIN UNNEST(sj.qty_cost_arr) WITH ORDINALITY AS u(val, ordinality)
),

-- Aggregate the sales per store and month
agg_sales AS (
    SELECT
        s_store_id,
        s_store_name,
        DATE_TRUNC('month', d_date) AS month,
        SUM(cs_net_paid)               AS total_net_paid,
        SUM(cs_ext_sales_price)        AS total_ext_sales,
        SUM(array_value)               AS sum_array_values,
        COUNT(*)                       AS cnt_sales
    FROM unnested_sales
    GROUP BY s_store_id, s_store_name, DATE_TRUNC('month', d_date)
),

-- Return side: join web_returns to store and reason via date_dim
returns_join AS (
    SELECT
        wr.wr_returned_date_sk,
        d_ret.d_date,
        s.s_store_id,
        wr.wr_return_amt,
        r.r_reason_desc
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d_ret
      ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN tpcds.store s
      ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN tpcds.reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_ret.d_year = 2001
),

agg_returns AS (
    SELECT
        s_store_id,
        DATE_TRUNC('month', d_date) AS month,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*)           AS cnt_returns
    FROM returns_join
    GROUP BY s_store_id, DATE_TRUNC('month', d_date)
),

-- Set difference: store‑month combos that have sales but no returns
sales_without_returns AS (
    SELECT s_store_id, month FROM agg_sales
    EXCEPT
    SELECT s_store_id, month FROM agg_returns
),

-- Full outer join of sales and returns (keep unmatched rows from both sides)
combined AS (
    SELECT
        COALESCE(a.s_store_id, r.s_store_id)               AS s_store_id,
        COALESCE(a.s_store_name, s2.s_store_name)          AS s_store_name,
        COALESCE(a.month, r.month)                         AS month,
        a.total_net_paid,
        a.total_ext_sales,
        a.sum_array_values,
        a.cnt_sales,
        r.total_return_amt,
        r.cnt_returns,
        (COALESCE(a.total_net_paid, 0) - COALESCE(r.total_return_amt, 0)) AS net_after_returns
    FROM agg_sales a
    FULL OUTER JOIN agg_returns r
      ON a.s_store_id = r.s_store_id AND a.month = r.month
    LEFT JOIN tpcds.store s2
      ON s2.s_store_id = COALESCE(a.s_store_id, r.s_store_id)
),

-- Final analytics: window functions and further filtering
final AS (
    SELECT
        s_store_id,
        s_store_name,
        month,
        total_net_paid,
        total_ext_sales,
        sum_array_values,
        total_return_amt,
        net_after_returns,
        cnt_sales,
        cnt_returns,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY month)                     AS month_seq,
        LAG(net_after_returns) OVER (PARTITION BY s_store_id ORDER BY month)           AS prev_month_net,
        SUM(net_after_returns) OVER (PARTITION BY s_store_id ORDER BY month
                                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_net
    FROM combined
    WHERE net_after_returns > 0
)
SELECT
    s_store_id,
    s_store_name,
    month,
    total_net_paid,
    total_ext_sales,
    sum_array_values,
    total_return_amt,
    net_after_returns,
    cnt_sales,
    cnt_returns,
    month_seq,
    prev_month_net,
    running_net
FROM final
WHERE s_store_id NOT IN (
    SELECT s_store_id FROM final WHERE cnt_sales = 0
)
ORDER BY s_store_name, month
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
