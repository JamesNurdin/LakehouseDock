WITH joined_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ca.ca_state,
        cd.cd_gender,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_order_number,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wp.wp_url,
        u.url_part
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS u(url_part)
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        ca_state,
        cd_gender,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        COUNT(DISTINCT url_part) AS distinct_url_parts
    FROM joined_data
    WHERE d_year BETWEEN 2001 AND 2003
      AND ca_state IN ('CA', 'TX', 'NY')
      AND cd_gender = 'M'
    GROUP BY d_year, d_month_seq, ca_state, cd_gender
)
SELECT
    d_year,
    d_month_seq,
    ca_state,
    cd_gender,
    total_quantity,
    total_sales,
    total_profit,
    total_return_qty,
    total_return_amount,
    distinct_orders,
    distinct_url_parts,
    total_profit / NULLIF(distinct_orders, 0) AS avg_profit_per_order
FROM agg
WHERE total_profit > 10000
  AND total_sales > 50000
  AND distinct_orders > 10
ORDER BY total_profit DESC
LIMIT 100
