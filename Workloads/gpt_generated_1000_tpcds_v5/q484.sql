WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ss.ss_store_sk,
        ws.ws_web_site_sk,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND t.t_am_pm = 'PM'
      AND t2.t_am_pm = 'PM'
      AND ss.ss_list_price > 10
      AND i.inv_quantity_on_hand > 0
      AND wsite.web_state = 'CA'
    GROUP BY d.d_year, d.d_month_seq, ss.ss_store_sk, ws.ws_web_site_sk
),
inv_month_avg AS (
    SELECT
        d.d_month_seq,
        AVG(i.inv_quantity_on_hand) AS avg_inv_qty
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_month_seq
)
SELECT
    sa.d_year,
    sa.d_month_seq,
    sa.ss_store_sk,
    sa.ws_web_site_sk,
    sa.store_sales_total,
    sa.web_sales_total,
    SUM(sa.store_sales_total) OVER (PARTITION BY sa.ss_store_sk ORDER BY sa.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_store_sales,
    RANK() OVER (PARTITION BY sa.ss_store_sk ORDER BY (sa.store_sales_total + sa.web_sales_total) DESC) AS sales_rank,
    im.avg_inv_qty
FROM sales_agg sa
JOIN inv_month_avg im ON sa.d_month_seq = im.d_month_seq
ORDER BY sa.d_year, sa.d_month_seq, sales_rank
LIMIT 100
