WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_return_tax,
        ws.ws_ext_wholesale_cost,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_tax,
        ws.ws_ship_date_sk,
        ws.ws_web_site_sk,
        ws.ws_sold_time_sk,
        t.t_meal_time,
        t.t_second,
        s.web_state,
        s.web_tax_percentage,
        s.web_suite_number
    FROM catalog_returns cr
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    WHERE t.t_meal_time = 'lunch'
      AND t.t_second IN (2, 8, 9)
      AND s.web_tax_percentage > 0.05
      AND s.web_suite_number = 'Suite 330'
      AND ws.ws_ext_wholesale_cost BETWEEN 1500 AND 3000
      AND ws.ws_sales_price > 20
      AND cr.cr_return_amount > 100
)
SELECT
    f.web_state,
    f.t_meal_time,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.ws_sales_price) AS avg_sales_price,
    COUNT(*) AS transaction_cnt,
    SUM(CASE WHEN f.ws_ext_wholesale_cost > 2500 THEN f.ws_ext_wholesale_cost ELSE 0 END) AS high_wholesale_cost_sum,
    GROUPING(f.web_state) AS grp_state,
    GROUPING(f.t_meal_time) AS grp_meal_time
FROM filtered f
GROUP BY ROLLUP (f.web_state, f.t_meal_time)
ORDER BY total_return_amount DESC
LIMIT 100
