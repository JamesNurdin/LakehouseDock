WITH sales_summary AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_manager,
        cc.cc_street_name,
        d.d_date,
        d.d_date_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        concat(cc.cc_manager, ' - ', cc.cc_street_name) AS manager_street,
        regexp_extract(d.d_day_name, '(\\w+)', 1) AS day_name_word
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        regexp_like(cc.cc_manager, '^A')
        AND cc.cc_street_name LIKE '%Sycamore%'
        AND d.d_year = 2002
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_call_center_id,
        cc.cc_manager,
        cc.cc_street_name,
        d.d_date,
        d.d_date_sk,
        concat(cc.cc_manager, ' - ', cc.cc_street_name),
        regexp_extract(d.d_day_name, '(\\w+)', 1)
)
SELECT
    ss.cc_call_center_id,
    ss.d_date,
    ss.manager_street,
    ss.day_name_word,
    ss.total_profit,
    ss.total_quantity,
    ss.distinct_orders,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_call_center_sk = ss.cc_call_center_sk
          AND cr.cr_returned_date_sk = ss.d_date_sk
    ) AS total_return_amount
FROM sales_summary ss
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    WHERE cr.cr_call_center_sk = ss.cc_call_center_sk
      AND cr.cr_returned_date_sk = ss.d_date_sk
)
ORDER BY ss.total_profit DESC
LIMIT 100
