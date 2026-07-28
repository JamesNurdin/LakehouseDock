WITH catalog_agg AS (
    SELECT cp.cp_type AS category,
           SUM(cr.cr_return_amount) AS total_return_amount,
           SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY cp.cp_type
)
SELECT 'catalog' AS source,
       category,
       total_return_amount,
       total_net_loss
FROM catalog_agg
UNION ALL
SELECT 'web' AS source,
       category,
       total_return_amount,
       total_net_loss
FROM (
    SELECT wsit.web_name AS category,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN customer c2 ON wr.wr_refunded_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON wr.wr_refunded_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON wr.wr_refunded_addr_sk = ca2.ca_address_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    WHERE wr.wr_net_loss > 0
    GROUP BY wsit.web_name
) web_agg
ORDER BY total_net_loss DESC
LIMIT 100
