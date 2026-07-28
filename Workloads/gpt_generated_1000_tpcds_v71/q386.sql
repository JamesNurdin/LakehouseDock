/* goal: Summarize net paid, tax and price statistics for catalog sales that meet specific tax, price and demographic conditions, limited to catalog pages with a particular catalog number and end date, and warehouses located in a given state. */
WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ext_tax,
        cs.cs_ext_list_price,
        cs.cs_net_paid
    FROM catalog_sales cs
    WHERE cs.cs_ext_tax > 100
      AND cs.cs_ext_list_price BETWEEN 1000 AND 5000
      AND cs.cs_ship_hdemo_sk = 2480
)
SELECT
    sm.sm_type AS ship_mode_type,
    w.w_warehouse_name AS warehouse_name,
    td.t_hour AS hour_of_day,
    COUNT(*) AS order_cnt,
    SUM(fs.cs_net_paid) AS total_net_paid,
    AVG(fs.cs_ext_tax) AS avg_ext_tax,
    MIN(fs.cs_ext_list_price) AS min_list_price,
    MAX(fs.cs_ext_list_price) AS max_list_price
FROM filtered_sales fs
JOIN time_dim td
    ON fs.cs_sold_time_sk = td.t_time_sk
JOIN ship_mode sm
    ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON fs.cs_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = fs.cs_catalog_page_sk
          AND cp.cp_catalog_number = 15
          AND cp.cp_end_date_sk = 2451084
          AND cp.cp_department = 'Sports'
    )
  AND w.w_state = 'CA'
GROUP BY
    sm.sm_type,
    w.w_warehouse_name,
    td.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
