WITH sales_metrics AS (
    SELECT
        ws.ws_order_number,
        wsite.web_name AS website,
        t.t_hour AS hour,
        CASE WHEN hd.hd_income_band_sk > 15 THEN 'High' ELSE 'Low' END AS income_class,
        ws.ws_net_profit AS net_profit,
        lt.order_return_amt AS total_return_for_order
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT COALESCE(SUM(wr.wr_return_amt), 0) AS order_return_amt
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
    ) lt
    WHERE hd.hd_dep_count > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND wsite.web_rec_start_date >= DATE '2000-01-01'
)
SELECT *
FROM (
    SELECT
        website,
        hour,
        income_class,
        'Net Profit' AS metric_name,
        SUM(net_profit) AS metric_amount
    FROM sales_metrics
    GROUP BY website, hour, income_class

    UNION ALL

    SELECT
        wsite.web_name,
        t.t_hour,
        CASE WHEN hd.hd_income_band_sk > 15 THEN 'High' ELSE 'Low' END,
        'Return Amount' AS metric_name,
        SUM(wr.wr_return_amt) AS metric_amount
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count > 0
      AND t.t_hour BETWEEN 9 AND 17
      AND wsite.web_rec_start_date >= DATE '2000-01-01'
    GROUP BY wsite.web_name, t.t_hour,
             CASE WHEN hd.hd_income_band_sk > 15 THEN 'High' ELSE 'Low' END
) AS combined
ORDER BY website, hour, income_class, metric_name DESC
LIMIT 100
