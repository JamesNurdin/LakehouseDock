WITH
sales_agg AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        SUM(cs.cs_net_paid)                           AS total_net_paid,
        SUM(cs.cs_net_profit)                         AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number)            AS order_cnt,
        AVG(cs.cs_ext_discount_amt)                   AS avg_discount,
        SUM(cs.cs_ext_ship_cost)                      AS total_ship_cost
    FROM catalog_sales cs
    GROUP BY
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk
),
store_agg AS (
    SELECT
        s.s_closed_date_sk,
        COUNT(DISTINCT s.s_store_sk)                 AS store_cnt,
        AVG(s.s_tax_percentage)                      AS avg_tax_percentage
    FROM store s
    GROUP BY s.s_closed_date_sk
),
web_page_agg AS (
    SELECT
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk,
        COUNT(DISTINCT wp.wp_web_page_sk)            AS page_cnt,
        SUM(CASE WHEN wp.wp_type = 'Product' THEN 1 ELSE 0 END) AS product_page_cnt,
        COUNT(DISTINCT wp.wp_customer_sk)            AS distinct_customer_cnt
    FROM web_page wp
    GROUP BY
        wp.wp_creation_date_sk,
        wp.wp_access_date_sk
)

SELECT
    sm.sm_type                                     AS ship_mode_type,
    d_sold.d_year                                  AS sold_year,
    d_sold.d_month_seq                             AS sold_month_seq,
    d_ship.d_year                                  AS ship_year,
    d_ship.d_month_seq                             AS ship_month_seq,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.order_cnt,
    ROUND(sa.avg_discount, 2)                      AS avg_discount,
    sa.total_ship_cost,
    COALESCE(sta.store_cnt, 0)                     AS stores_closed_on_ship_date,
    COALESCE(sta.avg_tax_percentage, 0)            AS avg_store_tax_percentage,
    COALESCE(wc.page_cnt, 0)                       AS pages_created_on_sold_date,
    COALESCE(wc.product_page_cnt, 0)               AS product_pages_created_on_sold_date,
    COALESCE(wa.page_cnt, 0)                       AS pages_accessed_on_ship_date,
    ROW_NUMBER() OVER (
        PARTITION BY sm.sm_type
        ORDER BY sa.total_net_paid DESC
    )                                              AS ship_mode_rank_by_sales
FROM sales_agg sa
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON sa.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN store_agg sta
    ON d_ship.d_date_sk = sta.s_closed_date_sk
LEFT JOIN web_page_agg wc
    ON d_sold.d_date_sk = wc.wp_creation_date_sk
LEFT JOIN web_page_agg wa
    ON d_ship.d_date_sk = wa.wp_access_date_sk
WHERE sm.sm_type IS NOT NULL
ORDER BY
    sm.sm_type,
    d_sold.d_year,
    d_sold.d_month_seq
LIMIT 100
