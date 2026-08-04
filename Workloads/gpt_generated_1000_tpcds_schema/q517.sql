WITH base_sales AS (
    SELECT
        d.d_year,
        i.i_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_ext_sales_price > 1000
      AND ws.ws_quantity >= 1
      AND i.i_current_price BETWEEN 10 AND 500
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND w.w_gmt_offset IS NOT NULL
    GROUP BY d.d_year, i.i_category
),
profitable_sales AS (
    SELECT d_year, i_category, total_sales, total_profit
    FROM base_sales
    WHERE total_profit > 0
),
non_profitable_sales AS (
    SELECT d_year, i_category, total_sales, total_profit
    FROM base_sales
    WHERE total_profit <= 0
),
sales_excluding_nonprof AS (
    SELECT d_year, i_category, total_sales, total_profit
    FROM profitable_sales
    EXCEPT
    SELECT d_year, i_category, total_sales, total_profit
    FROM non_profitable_sales
),
store_info AS (
    SELECT
        d.d_year,
        s.s_state,
        COUNT(*) AS store_count
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_gmt_offset >= -5
      AND s.s_tax_percentage < 10
      AND s.s_number_employees > 0
      AND s.s_market_desc LIKE '%Products%'
      AND s.s_city IS NOT NULL
    GROUP BY d.d_year, s.s_state
),
final AS (
    SELECT
        COALESCE(se.d_year, si.d_year) AS year,
        se.i_category,
        si.s_state,
        se.total_sales,
        se.total_profit,
        si.store_count
    FROM sales_excluding_nonprof se
    FULL OUTER JOIN store_info si ON se.d_year = si.d_year
)
SELECT
    year,
    i_category,
    s_state,
    total_sales,
    total_profit,
    store_count
FROM final
WHERE (total_sales > 5000 OR store_count > 5)
  AND total_profit IS NOT NULL
  AND (s_state IS NOT NULL OR i_category IS NOT NULL)
  AND (COALESCE(total_sales, 0) + COALESCE(store_count, 0)) > 0
  AND year >= 1998
  AND EXISTS (
        SELECT 1 FROM item i2
        WHERE i2.i_category = final.i_category
          AND i2.i_manager_id = 44
    )
ORDER BY year DESC, total_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
