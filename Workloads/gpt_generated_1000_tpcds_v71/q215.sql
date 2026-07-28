WITH sales_enriched AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        d_sold.d_year,
        d_sold.d_quarter_name,
        d_sold.d_moy,
        cp.cp_department,
        cp.cp_catalog_page_number,
        w.w_warehouse_name,
        w.w_state,
        p.p_promo_name,
        cc.cc_name
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d_sold.d_year = 2002                     -- filter 1: year
      AND d_sold.d_moy IN (2, 4, 11)               -- filter 2: months of year
      AND cp.cp_department = 'Home'               -- filter 3: department
      AND w.w_state = 'CA'                        -- filter 4: warehouse state
)
SELECT
    se.d_year,
    se.cp_department,
    se.w_warehouse_name,
    SUM(se.cs_ext_sales_price)                         AS total_sales,
    AVG(se.cs_net_profit)                              AS avg_profit,
    COUNT(*)                                           AS order_cnt,
    SUM(se.cs_ext_sales_price) / (
        SELECT AVG(cs_inner.cs_ext_sales_price)
        FROM tpcds.catalog_sales cs_inner
        WHERE cs_inner.cs_sold_date_sk IN (
            SELECT d_inner.d_date_sk
            FROM tpcds.date_dim d_inner
            WHERE d_inner.d_year = 2002
        )
    )                                                 AS sales_vs_overall_ratio,
    ROW_NUMBER() OVER (PARTITION BY se.d_year ORDER BY SUM(se.cs_ext_sales_price) DESC) AS sales_rank
FROM sales_enriched se
GROUP BY GROUPING SETS (
    (se.d_year, se.cp_department, se.w_warehouse_name),
    (se.d_year, se.cp_department),
    (se.d_year),
    ()
)
ORDER BY total_sales DESC NULLS LAST, se.d_year
