WITH site_quarter_sales AS (
    SELECT
        ws.web_site_id,
        ws.web_company_id,
        ws.web_county,
        d_sold.d_quarter_name,
        SUM(cs.cs_ext_sales_price) AS sum_sales_price,
        SUM(cs.cs_net_profit) AS sum_net_profit,
        COUNT(*) AS order_count,
        CASE
            WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit'
            ELSE 'Loss'
        END AS profit_flag
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_fy_year = 1906
        AND d_ship.d_quarter_seq = 13
        AND ws.web_company_id IN (1, 2, 3)
        AND ws.web_gmt_offset = -6.00
        AND ws.web_county = 'Barrow County'
        AND cs.cs_sales_price > 20.00
        AND cs.cs_quantity >= 2
    GROUP BY
        ws.web_site_id,
        ws.web_company_id,
        ws.web_county,
        d_sold.d_quarter_name
)
SELECT
    web_site_id,
    web_company_id,
    web_county,
    AVG(sum_net_profit) AS avg_quarter_net_profit,
    SUM(order_count) AS total_orders,
    CASE
        WHEN AVG(sum_net_profit) > 1000 THEN 'High Profit'
        WHEN AVG(sum_net_profit) > 0 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM site_quarter_sales
GROUP BY
    web_site_id,
    web_company_id,
    web_county
HAVING
    AVG(sum_net_profit) > 0
ORDER BY
    avg_quarter_net_profit DESC
LIMIT 100
