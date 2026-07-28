/*
Goal: Identify the most profitable catalog departments shipped by air in 2001, combining catalog and store sales, while excluding catalog orders that have any return records and ensuring the catalog page is active on the sale date. The query uses joins across all eight selected tables, applies multiple filters, aggregates key metrics, includes a subquery with DISTINCT, a window function, and an anti‑join, and returns the top 100 results.
*/
WITH filtered_sales AS (
    SELECT
        cp.cp_department,
        sm.sm_type,
        d_sold.d_year,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_paid DESC) AS dept_rank
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return
        ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_code IN (SELECT DISTINCT sm_code FROM ship_mode WHERE sm_type = 'AIR')
      AND cp.cp_department = 'Sports'
      AND ws.web_name = 'MainSite'
      -- anti‑join: exclude catalog orders that have any return quantity > 0
      AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
              AND cr2.cr_return_quantity > 0
      )
      -- ensure the catalog page is active on the sale date
      AND d_sold.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
      -- semi‑join via EXISTS to guarantee the ship mode exists (demonstrates DISTINCT sub‑query)
      AND EXISTS (
            SELECT 1 FROM ship_mode sm2
            WHERE sm2.sm_code = sm.sm_code
              AND sm2.sm_type = sm.sm_type
      )
)
SELECT
    cp_department,
    sm_type,
    d_year,
    COUNT(DISTINCT cs_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT ss_ticket_number) AS store_order_cnt,
    SUM(cs_net_paid) AS total_catalog_net,
    SUM(ss_net_paid) AS total_store_net,
    AVG(cs_ext_discount_amt) AS avg_catalog_discount,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    MAX(dept_rank) AS max_dept_rank
FROM filtered_sales
GROUP BY cp_department, sm_type, d_year
ORDER BY total_catalog_net DESC
LIMIT 100
