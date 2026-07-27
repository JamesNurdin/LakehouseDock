WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_hdemo_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ss.ss_quantity > 5
      AND ss.ss_net_profit > 0
)
SELECT
    s.s_store_name,
    d.d_year,
    i.i_category,
    cp.cp_department,
    ws.web_name,
    COUNT(DISTINCT ssa.ss_ticket_number) AS total_sales_transactions,
    SUM(ssa.ss_net_paid) AS total_sales_amount,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_return_amount,
    AVG(ssa.ss_net_profit) AS avg_net_profit,
    MIN(ssa.ss_net_paid) AS min_sales_amount,
    MAX(ssa.ss_net_paid) AS max_sales_amount,
    (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS category_avg_price
FROM sales ssa
JOIN date_dim d ON ssa.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ssa.ss_item_sk = i.i_item_sk
JOIN household_demographics hd ON ssa.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s ON ssa.ss_store_sk = s.s_store_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ssa.ss_ticket_number
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE i.i_current_price BETWEEN 20 AND 50
  AND s.s_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND ws.web_country = 'United States'
  AND hd.hd_income_band_sk = 5
  AND cp.cp_start_date_sk = d.d_date_sk
  AND wp.wp_creation_date_sk = d.d_date_sk
GROUP BY
    s.s_store_name,
    d.d_year,
    i.i_category,
    cp.cp_department,
    ws.web_name
LIMIT 100
