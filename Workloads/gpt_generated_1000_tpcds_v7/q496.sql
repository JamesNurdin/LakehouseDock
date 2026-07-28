WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_city,
        cc.cc_state,
        d.d_year
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        regexp_like(cc.cc_name, '^.*Center$')
        AND cc.cc_city LIKE '%York%'
        AND d.d_year = 2002
)
SELECT
    cc_call_center_id,
    CONCAT(cc_city, ', ', cc_state) AS city_state,
    SUBSTRING(cc_name, 1, 5) AS name_prefix,
    SUM(cs_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs_order_number) AS distinct_orders,
    REGEXP_EXTRACT(cc_name, '(\\w+)') AS first_word_of_name
FROM filtered_sales
GROUP BY
    cc_call_center_id,
    cc_city,
    cc_state,
    cc_name
ORDER BY total_sales DESC
LIMIT 100
