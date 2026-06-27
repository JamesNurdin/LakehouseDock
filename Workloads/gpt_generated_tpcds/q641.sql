WITH aggregated_sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        site.web_name,
        wh.w_warehouse_name,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN warehouse wh
        ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
    GROUP BY d.d_year, d.d_moy, site.web_name, wh.w_warehouse_name
)
SELECT
    a.d_year,
    a.d_moy,
    a.web_name,
    a.w_warehouse_name,
    a.total_profit,
    a.total_sales,
    a.order_count,
    a.unique_customers,
    a.avg_quantity,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM aggregated_sales a
ORDER BY a.d_year, profit_rank
LIMIT 20
