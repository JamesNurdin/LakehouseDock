WITH sales_summary AS (
    SELECT
        d.d_year,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        SUM(ss.ss_net_paid_inc_tax)               AS total_store_sales,
        SUM(ss.ss_net_profit)                     AS total_store_profit,
        SUM(cs.cs_ext_sales_price)                AS total_catalog_sales,
        SUM(cs.cs_ext_discount_amt)               AS total_catalog_discount,
        COUNT(DISTINCT cs.cs_order_number)        AS order_cnt,
        CASE
            WHEN SUM(ss.ss_net_paid_inc_tax) > 100000 THEN 'HIGH'
            ELSE 'LOW'
        END                                       AS sales_category
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_channel_tv = 'Y'
      AND p.p_channel_radio = 'N'
      AND cc.cc_state = 'CA'
      AND cp.cp_type = 'WEB'
      AND d.d_month_seq >= 1210
      AND d.d_quarter_name = '2001Q1'
    GROUP BY d.d_year, cc.cc_name, cp.cp_department, p.p_promo_name
)
SELECT
    d_year,
    cc_name,
    cp_department,
    sales_category,
    total_store_sales,
    total_store_profit,
    total_catalog_sales,
    order_cnt,
    RANK() OVER (ORDER BY total_store_sales DESC)                                   AS sales_rank,
    SUM(total_store_sales) OVER (
        PARTITION BY sales_category
        ORDER BY total_store_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                                              AS cum_sales_by_category
FROM sales_summary
WHERE total_store_sales > 50000
ORDER BY total_store_sales DESC
LIMIT 100
