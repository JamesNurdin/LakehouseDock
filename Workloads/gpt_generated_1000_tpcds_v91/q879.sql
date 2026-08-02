/*
  Goal: Calculate total sales across catalog, web, and store channels per customer, segmented by income category, and rank customers by combined sales.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cp.cp_department AS department,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales,
        SUM(cs.cs_quantity) AS total_cs_qty,
        MAX(ib.ib_upper_bound) AS ib_upper_bound,
        MAX(ib.ib_lower_bound) AS ib_lower_bound,
        MAX(p.p_discount_active) AS promo_active,
        MAX(w.w_warehouse_name) AS warehouse_name
    FROM catalog_sales cs
    JOIN customer c1 ON cs.cs_bill_customer_sk = c1.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 0
    GROUP BY cs.cs_bill_customer_sk, cs.cs_sold_date_sk, cp.cp_department
),
ss_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        s.s_store_name AS store_name,
        MAX(p.p_discount_active) AS promo_active,
        SUM(ss.ss_ext_sales_price) AS total_ss_sales,
        SUM(ss.ss_quantity) AS total_ss_qty,
        MAX(ib.ib_upper_bound) AS ib_upper_bound
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ss.ss_customer_sk, s.s_store_name
)
SELECT
    c.c_customer_id,
    cs_agg.department,
    CASE
        WHEN cs_agg.ib_upper_bound > 100000 THEN 'High Income'
        ELSE 'Low Income'
    END AS income_category,
    cs_agg.total_cs_sales,
    ss_agg.total_ss_sales,
    ws_agg.total_ws_sales,
    (cs_agg.total_cs_sales + COALESCE(ss_agg.total_ss_sales, 0) + COALESCE(ws_agg.total_ws_sales, 0)) AS total_all_sales,
    RANK() OVER (
        PARTITION BY CASE
            WHEN cs_agg.ib_upper_bound > 100000 THEN 'High Income'
            ELSE 'Low Income'
        END
        ORDER BY (cs_agg.total_cs_sales + COALESCE(ss_agg.total_ss_sales, 0) + COALESCE(ws_agg.total_ws_sales, 0)) DESC
    ) AS sales_rank,
    SUM(cs_agg.total_cs_sales + COALESCE(ss_agg.total_ss_sales, 0) + COALESCE(ws_agg.total_ws_sales, 0))
        OVER (PARTITION BY CASE
            WHEN cs_agg.ib_upper_bound > 100000 THEN 'High Income'
            ELSE 'Low Income'
        END) AS sum_sales_by_income_category
FROM cs_agg
JOIN customer c ON cs_agg.cust_sk = c.c_customer_sk
LEFT JOIN ss_agg ON cs_agg.cust_sk = ss_agg.cust_sk
LEFT JOIN LATERAL (
    SELECT
        SUM(ws.ws_ext_sales_price) AS total_ws_sales
    FROM web_sales ws
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE ws.ws_bill_customer_sk = cs_agg.cust_sk
) AS ws_agg ON TRUE
ORDER BY total_all_sales DESC
LIMIT 100
