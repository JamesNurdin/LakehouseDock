WITH sales_summary AS (
    SELECT
        s.s_store_name,
        i.i_category,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM store_sales ss
    RIGHT JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND s.s_state = 'CA'
      AND i.i_category = 'Electronics'
      AND r.r_reason_desc LIKE '%Damaged%'
    GROUP BY s.s_store_name, i.i_category, d.d_year
)
SELECT
    i_category,
    SUM(total_store_sales) AS sum_store_sales,
    SUM(total_web_sales) AS sum_web_sales,
    AVG(total_store_sales) AS avg_store_sales,
    AVG(total_web_sales) AS avg_web_sales,
    COUNT(*) AS store_count
FROM sales_summary
GROUP BY i_category
HAVING SUM(total_store_sales) > 50000
ORDER BY sum_store_sales DESC
LIMIT 100
