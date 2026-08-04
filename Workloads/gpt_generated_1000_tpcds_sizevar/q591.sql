WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        t.t_time,
        t.t_shift,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        wp.wp_url,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        r.r_reason_desc
    FROM web_sales ws
    LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE t.t_shift IN ('first', 'second', 'third')
      AND ca.ca_city IN ('San Francisco', 'New York', 'Chicago')
      AND ib.ib_lower_bound >= 50000
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
),
agg AS (
    SELECT
        ca.ca_city,
        t.t_shift,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_shift IN ('first', 'second')
      AND ca.ca_city IN ('San Francisco', 'Chicago')
      AND ib.ib_lower_bound >= 40000
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450500
    GROUP BY GROUPING SETS (
        (ca.ca_city, t.t_shift),
        (ca.ca_city),
        (t.t_shift),
        ()
    )
),
ranked AS (
    SELECT
        ca_city,
        t_shift,
        total_sales,
        order_cnt,
        RANK() OVER (PARTITION BY ca_city ORDER BY total_sales DESC) AS sales_rank_city,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS overall_sales_rank
    FROM agg
),
sub1 AS (
    SELECT ca_city, t_shift, total_sales, sales_rank_city
    FROM ranked
    WHERE total_sales > 10000
),
sub2 AS (
    SELECT ca_city, t_shift, total_sales, sales_rank_city
    FROM ranked
    WHERE order_cnt >= 5
),
unioned AS (
    SELECT * FROM sub1
    UNION
    SELECT * FROM sub2
),
intersected AS (
    SELECT ca_city, t_shift, total_sales
    FROM unioned
    INTERSECT
    SELECT ca_city, t_shift, total_sales
    FROM (
        SELECT ca_city, t_shift, total_sales
        FROM ranked
        WHERE overall_sales_rank <= 10
    ) AS top10
)
SELECT
    i.ca_city,
    i.t_shift,
    i.total_sales,
    ROW_NUMBER() OVER (PARTITION BY i.ca_city ORDER BY i.total_sales DESC) AS row_num,
    lt.max_city_sales
FROM intersected i
CROSS JOIN LATERAL (
    SELECT MAX(total_sales) AS max_city_sales
    FROM ranked r2
    WHERE r2.ca_city = i.ca_city
) lt
ORDER BY i.total_sales DESC
LIMIT 100
