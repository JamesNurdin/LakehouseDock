-- Goal: Rank warehouses by net profit and total sales for 2002 California call centers
-- that use air shipment mode and specific catalog numbers, and categorize sales volumes.

WITH joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        d.d_year,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_name,
        cc.cc_state,
        cp.cp_catalog_number,
        sm.sm_type,
        ws.web_site_id,
        ws.web_name
    FROM tpcds.catalog_sales cs
    INNER JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND cc.cc_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND cp.cp_catalog_number IN (5, 7, 16)
      AND cs.cs_ext_sales_price > 1000
),
agg AS (
    SELECT
        d_year,
        w_warehouse_name,
        w_state,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM joined
    GROUP BY d_year, w_warehouse_name, w_state
    HAVING SUM(cs_net_profit) > 0
)
SELECT
    d_year,
    w_warehouse_name,
    w_state,
    total_net_profit,
    total_sales,
    order_cnt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank,
    CASE
        WHEN total_sales > 50000 THEN 'High'
        WHEN total_sales > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM agg
ORDER BY d_year, profit_rank
LIMIT 100
