WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_cdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_coupon_amt,
        ss.ss_quantity,
        ARRAY[ss.ss_quantity, ss.ss_coupon_amt] AS qty_coupon_arr
    FROM store_sales ss
),
unnested_sales AS (
    SELECT
        sb.*,
        v.value AS metric_value,
        v.position AS metric_position
    FROM sales_base sb
    CROSS JOIN UNNEST(sb.qty_coupon_arr) WITH ORDINALITY AS v(value, position)
),
wp_full AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_autogen_flag,
        wp.wp_image_count,
        d_create.d_year AS creation_year,
        d_access.d_year AS access_year
    FROM date_dim d_create
    FULL OUTER JOIN web_page wp
        ON wp.wp_creation_date_sk = d_create.d_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
)
SELECT
    i.i_category,
    d_sold.d_year,
    cd.cd_gender,
    t.t_hour,
    us.metric_position AS metric_type,
    SUM(us.metric_value) AS metric_sum,
    SUM(us.ss_ext_sales_price) AS total_sales,
    COUNT(*) AS transaction_cnt
FROM unnested_sales us
JOIN store_sales ss
    ON ss.ss_sold_date_sk = us.ss_sold_date_sk
   AND ss.ss_sold_time_sk = us.ss_sold_time_sk
   AND ss.ss_item_sk = us.ss_item_sk
   AND ss.ss_cdemo_sk = us.ss_cdemo_sk
JOIN date_dim d_sold
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_sold_extra
    ON ss.ss_sold_date_sk = d_sold_extra.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN item i_dup
    ON ss.ss_item_sk = i_dup.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN wp_full wp
    ON wp.wp_image_count IS NOT NULL
WHERE d_sold.d_year = 2001
  AND d_sold.d_week_seq = 11
  AND wp.wp_autogen_flag = 'N'
GROUP BY i.i_category, d_sold.d_year, cd.cd_gender, t.t_hour, us.metric_position
ORDER BY total_sales DESC
LIMIT 100
