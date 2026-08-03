WITH sales_filtered AS (
    SELECT
        d.d_year AS year,
        i.i_category,
        i.i_brand,
        i.i_product_name,
        ws.ws_net_profit,
        ws.ws_order_number,
        -- string processing examples
        CASE WHEN regexp_like(i.i_product_name, '\\d') THEN 'HasDigit' ELSE 'NoDigit' END AS name_digit_flag,
        concat(i.i_brand, ' ', i.i_product_name) AS full_product_name,
        regexp_extract(i.i_product_name, '([A-Za-z]+)', 1) AS alpha_part
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE wsite.web_name LIKE '%Online%'
      AND regexp_like(i.i_product_name, '\\d')
      AND EXISTS (
            SELECT 1
            FROM web_returns wr
            JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
            WHERE wr.wr_order_number = ws.ws_order_number
              AND r.r_reason_desc LIKE 'Customer%'
        )
)
SELECT
    year,
    i_category,
    i_brand,
    SUM(ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_level,
    RANK() OVER (PARTITION BY year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM sales_filtered
GROUP BY year, i_category, i_brand
ORDER BY year, profit_rank
