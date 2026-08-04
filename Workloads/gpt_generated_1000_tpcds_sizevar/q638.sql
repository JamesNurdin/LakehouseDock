/*
  Goal: Calculate yearly sales and profit per item brand, filtering for a specific year, brand, income band and country, and then compute summary statistics while demonstrating advanced SQL features such as CTEs, TABLESAMPLE, FULL OUTER JOIN, CASE expressions, subqueries and multiple predicates.
*/
WITH joined_data AS (
    SELECT
        i.i_brand AS brand,
        d1.d_year AS year,
        cs.cs_ext_sales_price AS sales_price,
        cs.cs_net_profit AS net_profit,
        hd_bill.hd_income_band_sk AS income_band,
        ws.web_country AS web_country,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_net_paid AS store_net_paid,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        -- bring warehouse columns via full outer join sub‑query
        whinv.w_warehouse_name AS warehouse_name
    FROM (
        SELECT * FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ) cs
    INNER JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    INNER JOIN time_dim t1 ON cs.cs_sold_time_sk = t1.t_time_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN item i ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
    INNER JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
    INNER JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    -- full outer join between inventory and warehouse (allowed join rule)
    FULL OUTER JOIN (
        SELECT inv.*, w.w_warehouse_name, w.w_warehouse_sk
        FROM inventory inv
        FULL OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    ) whinv ON whinv.inv_item_sk = i.i_item_sk
    -- additional inner join to the same warehouse to satisfy the cs‑warehouse rule
    INNER JOIN warehouse w2 ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    INNER JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    INNER JOIN time_dim t2 ON ss.ss_sold_time_sk = t2.t_time_sk
    INNER JOIN web_site ws ON ws.web_open_date_sk = d2.d_date_sk
    WHERE
        d1.d_year = 2001                     -- predicate 1
        AND i.i_brand = 'Brand#12'           -- predicate 2
        AND hd_bill.hd_income_band_sk = 5    -- predicate 3
        AND ws.web_country = 'United States'-- predicate 4
        AND cs.cs_quantity > 1               -- predicate 5
),
agg_per_brand_year AS (
    SELECT
        brand,
        year,
        SUM(sales_price) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS txn_cnt
    FROM joined_data
    GROUP BY brand, year
)
SELECT
    brand,
    year,
    total_sales,
    total_profit,
    txn_cnt,
    CASE WHEN total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS overall_status,
    AVG(total_sales) OVER (PARTITION BY brand) AS avg_sales_per_brand
FROM agg_per_brand_year
WHERE total_sales > (
    SELECT AVG(cs_ext_sales_price) FROM catalog_sales
)   -- scalar subquery
ORDER BY total_sales DESC
