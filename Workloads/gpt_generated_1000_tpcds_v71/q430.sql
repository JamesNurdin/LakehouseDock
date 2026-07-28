WITH filtered_sales AS (
    SELECT
        cp.cp_department,
        d.d_year,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_net_paid_inc_ship_tax,
        cs.cs_sold_date_sk,
        cs.cs_bill_hdemo_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year = 1999                              -- filter 1: specific year
      AND cp.cp_department = 'Books'                  -- filter 2: department
      AND sm.sm_type = 'AIR'                          -- filter 3: ship mode type
      AND hd.hd_dep_count >= 2                        -- filter 4: household dependency count
      AND cs.cs_quantity > 1                          -- filter 5: minimum quantity per line
      AND cs.cs_net_paid_inc_ship_tax > 1000         -- filter 6: minimum revenue
      AND EXISTS (SELECT 1 FROM warehouse w
                  WHERE w.w_warehouse_sk = cs.cs_warehouse_sk
                    AND w.w_state = 'CA')          -- semi‑join (warehouse)
      AND EXISTS (SELECT 1 FROM store_sales ss
                  WHERE ss.ss_sold_date_sk = d.d_date_sk
                    AND ss.ss_hdemo_sk = hd.hd_demo_sk
                    AND ss.ss_quantity > 0)      -- semi‑join (store_sales)
      AND EXISTS (SELECT 1 FROM web_sales ws
                  WHERE ws.ws_sold_date_sk = d.d_date_sk
                    AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                    AND ws.ws_quantity > 0)      -- semi‑join (web_sales)
)
SELECT
    cp_department,
    d_year,
    SUM(cs_ext_sales_price) AS total_ext_sales_price,
    COUNT(*) AS order_count,
    SUM(cs_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY cp_department ORDER BY SUM(cs_ext_sales_price) DESC) AS dept_sales_rank
FROM filtered_sales
GROUP BY cp_department, d_year
ORDER BY total_ext_sales_price DESC
LIMIT 100
