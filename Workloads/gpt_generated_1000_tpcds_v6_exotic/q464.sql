/*
Goal: Analyze warehouse‑level sales performance for stores whose operating hours start with 8AM, extracting the start and end hour portions, limiting to stores in GA for the year 2001, and measuring how many of those sales had a corresponding web return.
*/
WITH sales_with_return_flag AS (
    SELECT
        cs.cs_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        s.s_store_id,
        s.s_hours,
        d_sold.d_year,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM web_returns wr
                WHERE wr.wr_order_number = cs.cs_order_number
                  AND wr.wr_returned_date_sk = cs.cs_sold_date_sk
            ) THEN 1
            ELSE 0
        END AS has_return,
        i.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(s.s_hours, '^8AM')
      AND s.s_hours LIKE '%AM'
      AND substring(s.s_state, 1, 2) = 'GA'
      AND d_sold.d_year = 2001
)
SELECT
    w_warehouse_id,
    w_state,
    regexp_extract(s_hours, '^([0-9]+[AP]M)', 1) AS start_hour,
    regexp_extract(s_hours, '-([0-9]+[AP]M)$', 1) AS end_hour,
    COUNT(*) AS sales_count,
    SUM(cs_quantity) AS total_quantity_sold,
    SUM(cs_ext_sales_price) AS total_sales_amount,
    AVG(cs_net_profit) AS avg_net_profit,
    SUM(inv_quantity_on_hand) / NULLIF(COUNT(*), 0) AS avg_inventory_on_sale_date,
    SUM(has_return) AS returns_count,
    ROUND(100.0 * SUM(has_return) / NULLIF(COUNT(*), 0), 2) AS return_rate_pct
FROM sales_with_return_flag
GROUP BY
    w_warehouse_id,
    w_state,
    regexp_extract(s_hours, '^([0-9]+[AP]M)', 1),
    regexp_extract(s_hours, '-([0-9]+[AP]M)$', 1)
ORDER BY total_sales_amount DESC
LIMIT 100
