WITH sales_agg AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(*) AS line_item_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND wsite.web_city = 'Springfield'
    GROUP BY ws.ws_order_number, ws.ws_sold_date_sk, ws.ws_web_site_sk
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY wr.wr_order_number
)
SELECT
    sa.ws_order_number,
    sa.total_net_paid,
    ra.total_return_amt,
    RANK() OVER (PARTITION BY sa.ws_web_site_sk ORDER BY sa.total_net_paid DESC) AS sales_rank,
    d.d_date,
    w.web_name,
    s.s_store_name,
    cp.cp_description
FROM sales_agg sa
JOIN returns_agg ra ON sa.ws_order_number = ra.wr_order_number
JOIN date_dim d ON sa.ws_sold_date_sk = d.d_date_sk
JOIN web_site w ON sa.ws_web_site_sk = w.web_site_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
WHERE sa.ws_order_number IN (
    SELECT order_num FROM (
        SELECT ws_order_number AS order_num FROM sales_agg WHERE total_net_paid > 1000
        INTERSECT
        SELECT wr_order_number AS order_num FROM returns_agg WHERE total_return_amt > 0
    )
)
AND EXISTS (
    SELECT 1 FROM web_site w2
    WHERE w2.web_site_sk = sa.ws_web_site_sk
      AND w2.web_mkt_class LIKE '%New%'
)
AND s.s_state = 'CA'
AND cp.cp_department = 'Electronics'
ORDER BY sa.total_net_paid DESC
LIMIT 100
