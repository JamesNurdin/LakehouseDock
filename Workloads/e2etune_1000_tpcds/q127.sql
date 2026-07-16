WITH
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type AS ship_mode,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND wp.wp_type = 'Home'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type AS ship_mode,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND wp.wp_type = 'Home'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type
),
catalog_ret_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND cc.cc_division_name IN ('pri','anti')
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.ship_mode,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_web_return_loss, 0) AS total_web_return_loss,
    COALESCE(c.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    (s.total_profit - COALESCE(r.total_web_return_loss, 0) - COALESCE(c.total_catalog_return_loss, 0)) AS net_contribution,
    s.order_cnt,
    COALESCE(r.return_cnt, 0) AS web_return_cnt,
    COALESCE(c.catalog_return_cnt, 0) AS catalog_return_cnt,
    ROUND((s.total_profit - COALESCE(r.total_web_return_loss, 0) - COALESCE(c.total_catalog_return_loss, 0)) / NULLIF(s.total_sales, 0), 4) AS profit_margin,
    RANK() OVER (PARTITION BY s.d_year ORDER BY s.total_sales DESC) AS sales_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.ship_mode = r.ship_mode
LEFT JOIN catalog_ret_agg c
    ON s.d_year = c.d_year
   AND s.d_month_seq = c.d_month_seq
ORDER BY s.d_year, s.d_month_seq, net_contribution DESC
LIMIT 200
