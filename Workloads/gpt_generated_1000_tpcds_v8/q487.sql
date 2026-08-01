WITH
    sales_agg AS (
        SELECT
            cs.cs_bill_customer_sk AS customer_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
            ROW_NUMBER() OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE td.t_hour BETWEEN 9 AND 17
        GROUP BY cs.cs_bill_customer_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            SUM(sr.sr_return_amt) AS total_returns,
            COUNT(DISTINCT sr.sr_item_sk) AS distinct_return_items
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        WHERE td.t_hour NOT BETWEEN 9 AND 17
        GROUP BY sr.sr_customer_sk
    ),
    intersect_customers AS (
        SELECT customer_sk FROM sales_agg
        INTERSECT
        SELECT customer_sk FROM returns_agg
    ),
    full_combined AS (
        SELECT
            s.customer_sk,
            s.total_sales,
            s.distinct_items,
            r.total_returns,
            r.distinct_return_items,
            s.sales_rank
        FROM sales_agg s
        FULL OUTER JOIN returns_agg r ON s.customer_sk = r.customer_sk
    ),
    filtered AS (
        SELECT
            fc.*,
            (
                SELECT MAX(cs2.cs_wholesale_cost)
                FROM catalog_sales cs2
                WHERE cs2.cs_bill_customer_sk = fc.customer_sk
            ) AS max_wholesale_cost
        FROM full_combined fc
        WHERE fc.customer_sk IS NOT NULL
          AND fc.customer_sk IN (SELECT customer_sk FROM intersect_customers)
          AND NOT EXISTS (
                SELECT 1 FROM reason r
                WHERE r.r_reason_sk = 1
                  AND r.r_reason_desc LIKE '%price%'
          )
          AND fc.customer_sk NOT IN (
                SELECT sr2.sr_customer_sk
                FROM store_returns sr2
                WHERE sr2.sr_return_amt > 5000
          )
    ),
    call_center_select AS (
        SELECT
            cc.cc_call_center_sk AS customer_sk,
            NULL AS total_sales,
            NULL AS distinct_items,
            NULL AS total_returns,
            NULL AS distinct_return_items,
            NULL AS sales_rank,
            NULL AS max_wholesale_cost
        FROM call_center cc
        WHERE cc.cc_state = 'CA'
          AND NOT EXISTS (
                SELECT 1 FROM catalog_sales cs
                WHERE cs.cs_call_center_sk = cc.cc_call_center_sk
                  AND cs.cs_ext_sales_price > 1000
          )
    )
SELECT
    customer_sk,
    total_sales,
    distinct_items,
    total_returns,
    distinct_return_items,
    sales_rank,
    max_wholesale_cost
FROM (
    SELECT
        customer_sk,
        total_sales,
        distinct_items,
        total_returns,
        distinct_return_items,
        sales_rank,
        max_wholesale_cost
    FROM filtered
    UNION
    SELECT
        customer_sk,
        total_sales,
        distinct_items,
        total_returns,
        distinct_return_items,
        sales_rank,
        max_wholesale_cost
    FROM call_center_select
) final_result
ORDER BY total_sales DESC NULLS LAST, total_returns DESC NULLS LAST
LIMIT 100
