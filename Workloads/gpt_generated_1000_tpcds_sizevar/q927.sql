WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_joined AS (
    SELECT
        ss.cs_order_number,
        ss.cs_net_paid_inc_tax,
        i.i_item_desc,
        w.w_warehouse_name,
        d.d_year,
        lc.year_code
    FROM sampled_sales ss
    JOIN item i
        ON ss.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ss.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
        ON ss.cs_sold_date_sk = d.d_date_sk
    JOIN LATERAL (
        SELECT regexp_extract(i.i_item_desc, '(\\d{4})') AS year_code
    ) lc ON TRUE
    WHERE i.i_item_desc LIKE '%toy%'
      AND w.w_zip LIKE '6%'
      AND d.d_year = 1999
),
returns_joined AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        i.i_item_desc,
        r.r_reason_desc,
        d.d_year,
        REPLACE(r.r_reason_desc, ' ', '_') AS reason_tag
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE regexp_like(r.r_reason_desc, 'fault')
      AND d.d_year = 1999
),
union_set AS (
    SELECT
        cs_order_number AS order_number,
        cs_net_paid_inc_tax AS amount,
        year_code
    FROM sales_joined
    UNION
    SELECT
        cr_order_number,
        cr_return_amount,
        NULL
    FROM returns_joined
),
except_set AS (
    SELECT order_number FROM union_set
    EXCEPT
    SELECT cs_order_number FROM sampled_sales
),
intersect_set AS (
    SELECT order_number FROM union_set
    INTERSECT
    SELECT cr_order_number FROM returns_joined
),
final_agg AS (
    SELECT
        u.order_number,
        SUM(u.amount) AS total_amount,
        COUNT(*) AS txn_count,
        MAX(u.year_code) AS extracted_year_code
    FROM union_set u
    WHERE u.order_number IN (SELECT order_number FROM intersect_set)
      AND u.order_number NOT IN (SELECT order_number FROM except_set)
    GROUP BY u.order_number
)
SELECT
    f.order_number,
    f.total_amount,
    f.txn_count,
    f.extracted_year_code
FROM final_agg f
ORDER BY f.total_amount DESC
LIMIT 100
