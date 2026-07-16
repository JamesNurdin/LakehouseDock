WITH date_range AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq
    FROM date_dim
    WHERE d_date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
sales_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank,
        MAX(ss.ss_sold_date_sk) AS last_sold_date_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_range d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_product_name, d.d_date, d.d_year, d.d_month_seq
),
returns_data AS (
    SELECT
        sr.sr_store_sk,
        i.i_item_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY sr.sr_store_sk, i.i_item_sk
),
promo_data AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS orders_using_promo,
        SUM(cs.cs_ext_sales_price) AS promo_sales
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk, p.p_item_sk
),
sales_with_returns AS (
    SELECT
        sd.s_store_sk,
        sd.s_store_name,
        sd.i_item_sk,
        sd.i_product_name,
        sd.d_date,
        sd.total_sales,
        COALESCE(rd.total_return_amt, CAST(0 AS decimal(15,2))) AS total_return_amt,
        sd.total_profit,
        sd.sales_cnt,
        COALESCE(rd.return_cnt, CAST(0 AS BIGINT)) AS return_cnt,
        CASE
            WHEN sd.total_sales = 0 THEN NULL
            ELSE rd.total_return_amt / sd.total_sales
        END AS return_rate,
        sd.sales_rank,
        DENSE_RANK() OVER (PARTITION BY sd.s_store_sk ORDER BY sd.total_profit DESC) AS profit_rank,
        CONCAT(sd.s_store_name, ' - ', sd.i_product_name) AS store_item_label,
        (SELECT AVG(ss2.ss_net_profit)
         FROM store_sales ss2
         JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
         WHERE ss2.ss_item_sk = sd.i_item_sk
           AND d2.d_month_seq = sd.d_month_seq
        ) AS avg_item_profit_month,
        SUM(sd.total_sales) OVER (PARTITION BY sd.d_date) AS total_sales_per_date,
        CASE WHEN EXISTS (
            SELECT 1 FROM promo_data pd WHERE pd.p_item_sk = sd.i_item_sk
        ) THEN 1 ELSE 0 END AS has_active_promo
    FROM sales_data sd
    LEFT JOIN returns_data rd
      ON sd.s_store_sk = rd.sr_store_sk AND sd.i_item_sk = rd.i_item_sk
),
returns_without_sales AS (
    SELECT
        sr.sr_store_sk,
        i.i_item_sk,
        i.i_product_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss
      ON ss.ss_store_sk = sr.sr_store_sk AND ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_item_sk IS NULL
    GROUP BY sr.sr_store_sk, i.i_item_sk, i.i_product_name
)
SELECT
    swr.s_store_sk,
    swr.s_store_name,
    swr.i_item_sk,
    swr.i_product_name,
    swr.d_date,
    swr.total_sales,
    swr.total_return_amt,
    swr.total_profit,
    swr.sales_cnt,
    swr.return_cnt,
    swr.return_rate,
    swr.sales_rank,
    swr.profit_rank,
    swr.store_item_label,
    swr.avg_item_profit_month,
    swr.total_sales_per_date,
    swr.has_active_promo
FROM sales_with_returns swr
WHERE swr.sales_rank <= 10
UNION ALL
SELECT
    -1 AS s_store_sk,
    'Returns Without Sales' AS s_store_name,
    rws.i_item_sk,
    rws.i_product_name,
    CAST(NULL AS date) AS d_date,
    CAST(0 AS decimal(15,2)) AS total_sales,
    rws.total_return_amt,
    CAST(0 AS decimal(15,2)) AS total_profit,
    CAST(0 AS BIGINT) AS sales_cnt,
    rws.return_cnt,
    CAST(NULL AS decimal(15,2)) AS return_rate,
    CAST(NULL AS BIGINT) AS sales_rank,
    CAST(NULL AS BIGINT) AS profit_rank,
    CONCAT('Return Only - ', rws.i_product_name) AS store_item_label,
    CAST(NULL AS decimal(15,2)) AS avg_item_profit_month,
    CAST(NULL AS decimal(15,2)) AS total_sales_per_date,
    CAST(0 AS integer) AS has_active_promo
FROM returns_without_sales rws
ORDER BY s_store_name, total_sales DESC
LIMIT 200
