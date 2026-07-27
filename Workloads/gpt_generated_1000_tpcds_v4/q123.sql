/*
Goal: Calculate sales and return performance metrics per store, item category and hour of day for a filtered subset of data.
*/
WITH sales AS (
    SELECT
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk
    FROM catalog_sales cs
    WHERE cs.cs_sales_price > 50
),
returns AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_reason_sk,
        sr.sr_store_sk
    FROM store_returns sr
)
SELECT
    s.s_store_id AS store_id,
    s.s_store_name,
    i.i_category AS item_category,
    td.t_hour AS hour_of_day,
    SUM(sa.cs_ext_sales_price) AS total_sales_amount,
    SUM(rt.sr_return_amt) AS total_return_amount,
    SUM(sa.cs_quantity) AS total_quantity_sold,
    AVG(sa.cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MIN(sa.cs_sales_price) AS min_sales_price,
    MAX(sa.cs_sales_price) AS max_sales_price
FROM sales sa
JOIN catalog_page cp
  ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i
  ON sa.cs_item_sk = i.i_item_sk
JOIN warehouse w
  ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
  ON sa.cs_sold_time_sk = td.t_time_sk
JOIN customer c
  ON sa.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN returns rt
  ON rt.sr_item_sk = i.i_item_sk
 AND rt.sr_return_time_sk = td.t_time_sk
 AND rt.sr_customer_sk = c.c_customer_sk
JOIN store s
  ON rt.sr_store_sk = s.s_store_sk
JOIN reason r
  ON rt.sr_reason_sk = r.r_reason_sk
WHERE i.i_category_id = 5
  AND w.w_suite_number = 'Suite 0'
  AND s.s_state = 'CA'
  AND c.c_birth_month = 7
  AND td.t_hour BETWEEN 9 AND 17
  AND r.r_reason_desc = 'Damaged'
GROUP BY s.s_store_id, s.s_store_name, i.i_category, td.t_hour
ORDER BY total_sales_amount DESC
LIMIT 100
