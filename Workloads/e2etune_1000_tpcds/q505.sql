WITH site_monthly_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws_site.web_name,
        ws_site.web_state,
        sd.d_year,
        sd.d_quarter_name,
        sd.d_moy AS month_of_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
        sd.d_year = 1902
        AND ws_site.web_state IN ('CA', 'NY', 'TX')
        AND wp.wp_type = 'product'
    GROUP BY
        ws.ws_web_site_sk,
        ws_site.web_name,
        ws_site.web_state,
        sd.d_year,
        sd.d_quarter_name,
        sd.d_moy
    HAVING SUM(ws.ws_net_profit) > 10000
)
SELECT
    *,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    (total_net_profit * 100.0) / SUM(total_net_profit) OVER (PARTITION BY d_year) AS profit_pct_of_year
FROM site_monthly_sales
ORDER BY profit_rank
LIMIT 100
