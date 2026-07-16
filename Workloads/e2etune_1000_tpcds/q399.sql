WITH returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND d_ret.d_quarter_name = 'Q1'
    GROUP BY wr.wr_order_number, wr.wr_item_sk
),
sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        d.d_year,
        d.d_quarter_name,
        cp.cp_department,
        ws_site.web_market_manager,
        p.p_promo_name,
        p.p_channel_tv
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND d.d_quarter_name = 'Q1'
      AND cp.cp_department = 'DEPARTMENT'
      AND cp.cp_end_date_sk >= d.d_date_sk
      AND p.p_channel_tv = 'Y'
)
SELECT
    s.web_market_manager,
    s.cp_department,
    s.d_year,
    s.d_quarter_name,
    SUM(s.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.total_return_amount, 0)) AS total_return_amount,
    SUM(s.ws_net_profit) - SUM(COALESCE(r.total_return_amount, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT s.ws_order_number) AS distinct_orders,
    SUM(COALESCE(r.return_count, 0)) AS total_returns,
    approx_percentile(s.ws_net_profit, 0.5) AS median_profit_per_order
FROM sales_agg s
LEFT JOIN returns_agg r
    ON r.wr_order_number = s.ws_order_number
    AND r.wr_item_sk = s.ws_item_sk
GROUP BY s.web_market_manager, s.cp_department, s.d_year, s.d_quarter_name
ORDER BY total_net_profit DESC
LIMIT 50
