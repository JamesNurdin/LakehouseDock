WITH
    store_dates AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            d.d_date,
            d.d_year
        FROM store s
        JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ),
    call_center_dates AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_name,
            d.d_date,
            d.d_year
        FROM call_center cc
        JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
        WHERE d.d_year = 2002
    ),
    full_store_cc AS (
        SELECT
            COALESCE(sd.d_year, cc.d_year) AS d_year,
            sd.s_store_sk,
            sd.s_store_name,
            cc.cc_call_center_sk,
            cc.cc_name AS call_center_name
        FROM store_dates sd
        FULL OUTER JOIN call_center_dates cc
            ON sd.d_date = cc.d_date
    ),
    sales_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'sales' AS metric_type,
            SUM(cs.cs_net_paid_inc_ship) AS metric_value
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE d.d_year = 2002
          AND i.i_category = 'Sports'
        GROUP BY d.d_year, d.d_month_seq
    ),
    returns_agg AS (
        SELECT
            d.d_year AS year,
            d.d_month_seq AS month,
            'returns' AS metric_type,
            SUM(cr.cr_return_amount) AS metric_value
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE d.d_year = 2002
          AND i.i_category = 'Sports'
        GROUP BY d.d_year, d.d_month_seq
    ),
    union_data AS (
        SELECT year, month, metric_type, metric_value FROM sales_agg
        UNION ALL
        SELECT year, month, metric_type, metric_value FROM returns_agg
    )
SELECT
    u.year,
    u.month,
    u.metric_type,
    u.metric_value,
    (SELECT COUNT(*) FROM full_store_cc f WHERE f.d_year = u.year) AS total_entities
FROM union_data u
ORDER BY u.year, u.month, u.metric_type
LIMIT 100
