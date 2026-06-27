WITH sales_2000 AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_web_page_sk,
        ws.ws_bill_customer_sk,
        ws.ws_ship_customer_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        d.d_date,
        d.d_year
    FROM web_sales ws
    JOIN date_dim d
      ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
agg_sales AS (
    SELECT
        site.web_site_id,
        site.web_name,
        wp.wp_type,
        format_datetime(s.d_date, '%Y-%m') AS sale_month,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_ext_sales_price) AS total_sales,
        SUM(s.ws_ext_discount_amt) AS total_discount,
        SUM(s.ws_net_profit) AS total_profit,
        COUNT(DISTINCT s.ws_bill_customer_sk) AS distinct_bill_customers,
        COUNT(DISTINCT s.ws_ship_customer_sk) AS distinct_ship_customers,
        AVG(s.ws_ext_discount_amt / NULLIF(s.ws_ext_sales_price, 0)) AS avg_discount_rate
    FROM sales_2000 s
    JOIN web_site site
      ON s.ws_web_site_sk = site.web_site_sk
    JOIN web_page wp
      ON s.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        site.web_site_id,
        site.web_name,
        wp.wp_type,
        format_datetime(s.d_date, '%Y-%m')
)
SELECT
    a.web_site_id,
    a.web_name,
    a.wp_type,
    a.sale_month,
    a.total_quantity,
    a.total_sales,
    a.total_discount,
    a.total_profit,
    a.distinct_bill_customers,
    a.distinct_ship_customers,
    a.avg_discount_rate,
    RANK() OVER (PARTITION BY a.sale_month ORDER BY a.total_profit DESC) AS profit_rank_by_month
FROM agg_sales a
ORDER BY a.sale_month, profit_rank_by_month
