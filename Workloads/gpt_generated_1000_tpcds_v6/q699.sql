WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d_sold.d_year,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        ws.ws_web_site_sk,
        site.web_name,
        ws.ws_promo_sk,
        p.p_promo_name,
        ws.ws_web_page_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d_sold.d_year BETWEEN 2001 AND 2002
      AND w.w_state IN ('CA', 'TX', 'NY')
      AND sm.sm_type = 'AIR'
      AND p.p_channel_tv = 'Y'
      AND site.web_class = 'Unknown'
      AND ws.ws_quantity > 1
      AND wp.wp_type = 'Content'
    GROUP BY
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d_sold.d_year,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        ws.ws_web_site_sk,
        site.web_name,
        ws.ws_promo_sk,
        p.p_promo_name,
        ws.ws_web_page_sk
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        d_ret.d_year AS return_year,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND sr.sr_return_quantity > 0
    GROUP BY
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        d_ret.d_year
)
SELECT
    s.d_year,
    s.w_warehouse_name,
    s.sm_type,
    s.web_name,
    s.p_promo_name,
    s.total_sales,
    s.total_profit,
    s.sales_cnt,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    (s.total_sales - COALESCE(r.total_return_amt, 0)) AS net_sales_after_returns,
    CASE WHEN s.total_sales > 100000 THEN 'High' ELSE 'Normal' END AS sales_category
FROM sales_agg s
LEFT OUTER JOIN returns_agg r
    ON s.ws_order_number = r.sr_ticket_number
WHERE EXISTS (
    SELECT 1
    FROM web_page wp2
    WHERE wp2.wp_web_page_sk = s.ws_web_page_sk
      AND wp2.wp_type = 'Content'
)
ORDER BY s.total_sales DESC
LIMIT 100
