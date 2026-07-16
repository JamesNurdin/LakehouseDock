WITH unified_sales AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_store_sk AS store_sk,
        CAST(null AS integer) AS catalog_page_sk,
        CAST(null AS integer) AS web_page_sk,
        ss_item_sk AS item_sk,
        ss_quantity AS quantity,
        ss_sales_price AS unit_price,
        ss_ext_sales_price AS sales,
        ss_net_profit AS profit,
        ss_ext_discount_amt AS discount,
        ss_promo_sk AS promo_sk,
        ss_customer_sk AS customer_sk,
        'store' AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk AS date_sk,
        CAST(null AS integer) AS store_sk,
        cs_catalog_page_sk AS catalog_page_sk,
        CAST(null AS integer) AS web_page_sk,
        cs_item_sk AS item_sk,
        cs_quantity AS quantity,
        cs_sales_price AS unit_price,
        cs_ext_sales_price AS sales,
        cs_net_profit AS profit,
        cs_ext_discount_amt AS discount,
        cs_promo_sk AS promo_sk,
        cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk AS date_sk,
        CAST(null AS integer) AS store_sk,
        CAST(null AS integer) AS catalog_page_sk,
        ws_web_page_sk AS web_page_sk,
        ws_item_sk AS item_sk,
        ws_quantity AS quantity,
        ws_sales_price AS unit_price,
        ws_ext_sales_price AS sales,
        ws_net_profit AS profit,
        ws_ext_discount_amt AS discount,
        ws_promo_sk AS promo_sk,
        ws_bill_customer_sk AS customer_sk,
        'web' AS channel
    FROM web_sales
),
aggregated_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        us.channel,
        COALESCE(s.s_state, cp.cp_department, wp.wp_type) AS region,
        i.i_category,
        i.i_brand,
        SUM(us.sales) AS total_sales,
        SUM(us.profit) AS total_profit,
        SUM(us.discount) AS total_discount,
        COUNT(DISTINCT us.item_sk) AS distinct_items,
        AVG(us.sales) AS avg_sales_per_order,
        MAX(us.sales) AS max_sales,
        MIN(us.sales) AS min_sales,
        SUM(us.sales) / NULLIF(SUM(us.quantity), 0) AS avg_price_per_unit
    FROM unified_sales us
    JOIN date_dim d ON d.d_date_sk = us.date_sk
    LEFT JOIN store s ON s.s_store_sk = us.store_sk
    LEFT JOIN catalog_page cp ON cp.cp_catalog_page_sk = us.catalog_page_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = us.web_page_sk
    JOIN item i ON i.i_item_sk = us.item_sk
    LEFT JOIN promotion p ON p.p_promo_sk = us.promo_sk
    LEFT JOIN customer c ON c.c_customer_sk = us.customer_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        us.channel,
        COALESCE(s.s_state, cp.cp_department, wp.wp_type),
        i.i_category,
        i.i_brand
    HAVING SUM(us.sales) > 100000
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.channel,
    a.region,
    a.i_category,
    a.i_brand,
    a.total_sales,
    a.total_profit,
    a.total_discount,
    a.distinct_items,
    a.avg_sales_per_order,
    a.max_sales,
    a.min_sales,
    a.avg_price_per_unit,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_sales DESC) AS sales_rank,
    SUM(a.total_sales) OVER (PARTITION BY a.channel, a.d_year ORDER BY a.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_sales_trend
FROM aggregated_sales a
ORDER BY a.d_year, a.d_month_seq, a.channel, a.total_sales DESC
