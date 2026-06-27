WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        date_trunc('month', d_sales.d_date) AS month_start,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    GROUP BY
        cc.cc_call_center_id,
        date_trunc('month', d_sales.d_date)
),
returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        date_trunc('month', d_return.d_date) AS month_start,
        SUM(cr.cr_net_loss) AS total_returns_loss,
        COUNT(DISTINCT cr.cr_order_number) AS num_return_orders,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d_return
        ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY
        cc.cc_call_center_id,
        date_trunc('month', d_return.d_date)
),
website_agg AS (
    SELECT
        date_trunc('month', d_web.d_date) AS month_start,
        COUNT(DISTINCT ws.web_site_id) AS num_websites_opened
    FROM web_site ws
    JOIN date_dim d_web
        ON ws.web_open_date_sk = d_web.d_date_sk
    GROUP BY
        date_trunc('month', d_web.d_date)
)
SELECT
    s.cc_call_center_id,
    s.month_start,
    s.total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    (s.total_sales_profit - COALESCE(r.total_returns_loss, 0)) AS net_profit_after_returns,
    s.num_orders,
    COALESCE(r.num_return_orders, 0) AS num_return_orders,
    s.total_quantity,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(w.num_websites_opened, 0) AS num_websites_opened
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cc_call_center_id = r.cc_call_center_id
    AND s.month_start = r.month_start
LEFT JOIN website_agg w
    ON s.month_start = w.month_start
ORDER BY s.month_start, s.cc_call_center_id
