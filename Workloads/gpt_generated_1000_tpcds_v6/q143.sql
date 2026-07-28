WITH store_metrics AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_division_id,
        d.d_year,
        SUM(ss.ss_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        CASE
            WHEN SUM(ss.ss_net_paid_inc_tax) > 50000 THEN 'HIGH'
            ELSE 'LOW'
        END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY s.s_division_id ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank_in_division
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE s.s_division_id = 1
      AND d.d_year = 2002
      AND cc.cc_state = 'CA'
    GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_division_id, d.d_year
    HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
)
SELECT
    division_id,
    AVG(total_sales_inc_tax) AS avg_sales_inc_tax,
    SUM(total_return_amount) AS sum_return_amount,
    COUNT(*) AS store_count
FROM (
    SELECT
        sm.s_division_id AS division_id,
        sm.total_sales_inc_tax,
        sm.total_return_amount,
        sm.sales_category,
        sm.sales_rank_in_division,
        sm.s_city
    FROM store_metrics sm
    WHERE sm.sales_category = 'HIGH'
      AND sm.s_city IN ('Friendship', 'Buena Vista')
      AND sm.sales_rank_in_division <= 5
) sub
GROUP BY division_id
ORDER BY avg_sales_inc_tax DESC
