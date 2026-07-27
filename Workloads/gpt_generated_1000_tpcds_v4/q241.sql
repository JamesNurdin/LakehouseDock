WITH sales_by_site AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_ext_wholesale_cost,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_ext_ship_cost
    FROM tpcds.web_sales ws
    JOIN tpcds.web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        w.web_street_type IN ('Court', 'Avenue', 'Blvd')
        AND w.web_mkt_desc LIKE '%police%'
        AND w.web_company_id IN (1, 2, 4)
        AND ws.ws_warehouse_sk IN (1, 8, 14)
        AND ws.ws_ext_wholesale_cost > 1000
        AND w.web_rec_start_date >= DATE '2000-01-01'
),
agg_site AS (
    SELECT
        ws.ws_web_site_sk AS web_site_sk,
        COUNT(*) AS order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM sales_by_site ws
    GROUP BY ws.ws_web_site_sk
)
SELECT
    w.web_site_id,
    w.web_name,
    a.order_cnt,
    a.total_sales,
    a.total_discount,
    a.avg_profit
FROM agg_site a
JOIN tpcds.web_site w
    ON a.web_site_sk = w.web_site_sk
WHERE a.total_sales > 50000
  AND a.avg_profit > 0
ORDER BY a.total_sales DESC
LIMIT 20
