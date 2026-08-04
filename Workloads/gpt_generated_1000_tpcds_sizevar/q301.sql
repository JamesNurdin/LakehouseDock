WITH agg_sales AS (
    SELECT
        cs_catalog_page_sk,
        cs_sold_date_sk,
        cs_warehouse_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*)                AS sales_cnt
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_quantity > (
        SELECT MAX(cs_quantity)
        FROM catalog_sales
        WHERE cs_ship_date_sk = 2451087
    )
    GROUP BY cs_catalog_page_sk, cs_sold_date_sk, cs_warehouse_sk
)

SELECT
    d_sales.d_year,
    cp.cp_department,
    s.s_store_name,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    agg.total_sales,
    agg.sales_cnt,
    SUM(sr.sr_return_amt)            AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM agg_sales agg
JOIN catalog_page cp ON agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sales ON agg.cs_sold_date_sk = d_sales.d_date_sk
JOIN warehouse w ON agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sales.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_year = 2001
    AND cp.cp_type = 'monthly'
    AND s.s_state = 'CA'
    AND r.r_reason_desc LIKE '%damaged%'
    AND hd.hd_buy_potential = 'High'
    AND ib.ib_upper_bound >= 50000
GROUP BY
    d_sales.d_year,
    cp.cp_department,
    s.s_store_name,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    agg.total_sales,
    agg.sales_cnt

UNION DISTINCT

SELECT
    d_sales.d_year,
    cp.cp_department,
    s.s_store_name,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    agg.total_sales,
    agg.sales_cnt,
    SUM(sr.sr_return_amt)            AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders
FROM agg_sales agg
JOIN catalog_page cp ON agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_sales ON agg.cs_sold_date_sk = d_sales.d_date_sk
JOIN warehouse w ON agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_sales.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
WHERE
    d_sales.d_year = 2002
    AND cp.cp_type = 'quarterly'
    AND s.s_state = 'NY'
    AND r.r_reason_desc LIKE '%defective%'
    AND hd.hd_buy_potential = 'Medium'
    AND ib.ib_upper_bound >= 75000
GROUP BY
    d_sales.d_year,
    cp.cp_department,
    s.s_store_name,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    agg.total_sales,
    agg.sales_cnt
ORDER BY total_sales DESC
OFFSET 0 LIMIT 100
