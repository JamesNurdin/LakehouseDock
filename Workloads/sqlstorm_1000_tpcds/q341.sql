WITH sales_raw AS (
    SELECT 'Store' AS sales_chan,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_customer_sk AS customer_sk,
           ss.ss_quantity AS quantity,
           ss.ss_ext_sales_price AS ext_sales_price,
           ss.ss_net_profit AS net_profit,
           s.s_state AS location_state,
           ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    UNION ALL
    SELECT 'Catalog' AS sales_chan,
           cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_bill_customer_sk,
           cs.cs_quantity,
           cs.cs_ext_sales_price,
           cs.cs_net_profit,
           cc.cc_state,
           CAST(NULL AS BIGINT) AS ticket_number
    FROM catalog_sales cs
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    UNION ALL
    SELECT 'Web' AS sales_chan,
           ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_bill_customer_sk,
           ws.ws_quantity,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           w.web_state,
           CAST(NULL AS BIGINT) AS ticket_number
    FROM web_sales ws
    LEFT JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
),
customer_returns AS (
    SELECT c_customer_sk,
           SUM(COALESCE(sr_return_quantity, 0)) AS store_ret_qty,
           SUM(COALESCE(cr_return_quantity, 0)) AS catalog_ret_qty,
           SUM(COALESCE(wr_return_quantity, 0)) AS web_ret_qty
    FROM (
        SELECT sr.sr_customer_sk AS c_customer_sk,
               sr.sr_return_quantity,
               NULL AS cr_return_quantity,
               NULL AS wr_return_quantity
        FROM store_returns sr
        UNION ALL
        SELECT cr.cr_returning_customer_sk,
               NULL,
               cr.cr_return_quantity,
               NULL
        FROM catalog_returns cr
        UNION ALL
        SELECT wr.wr_returning_customer_sk,
               NULL,
               NULL,
               wr.wr_return_quantity
        FROM web_returns wr
    ) t
    GROUP BY c_customer_sk
),
customer_sales AS (
    SELECT c_customer_sk,
           SUM(COALESCE(ss_qty, 0) + COALESCE(cs_qty, 0) + COALESCE(ws_qty, 0)) AS total_qty,
           SUM(COALESCE(ss_sales, 0) + COALESCE(cs_sales, 0) + COALESCE(ws_sales, 0)) AS total_sales
    FROM (
        SELECT ss.ss_customer_sk AS c_customer_sk,
               ss.ss_quantity AS ss_qty,
               NULL AS cs_qty,
               NULL AS ws_qty,
               ss.ss_ext_sales_price AS ss_sales,
               NULL AS cs_sales,
               NULL AS ws_sales
        FROM store_sales ss
        UNION ALL
        SELECT cs.cs_bill_customer_sk,
               NULL,
               cs.cs_quantity,
               NULL,
               NULL,
               cs.cs_ext_sales_price,
               NULL
        FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_bill_customer_sk,
               NULL,
               NULL,
               ws.ws_quantity,
               NULL,
               NULL,
               ws.ws_ext_sales_price
        FROM web_sales ws
    ) t
    GROUP BY c_customer_sk
),
joined AS (
    SELECT sr.sales_chan,
           sr.date_sk,
           sr.item_sk,
           sr.customer_sk,
           sr.quantity,
           sr.ext_sales_price,
           sr.net_profit,
           sr.location_state,
           sr.ticket_number,
           COALESCE(cr.store_ret_qty, 0) + COALESCE(cr.catalog_ret_qty, 0) + COALESCE(cr.web_ret_qty, 0) AS total_ret_qty,
           COALESCE(cs.total_qty, 0) AS total_sales_qty,
           CASE
               WHEN COALESCE(cs.total_qty, 0) = 0 THEN 0
               ELSE (COALESCE(cr.store_ret_qty, 0) + COALESCE(cr.catalog_ret_qty, 0) + COALESCE(cr.web_ret_qty, 0)) * 1.0 / cs.total_qty
           END AS return_rate,
           CONCAT('CUST_', CAST(sr.customer_sk AS VARCHAR), '_', COALESCE(c.c_email_address, 'NOEMAIL')) AS cust_key,
           ROW_NUMBER() OVER (PARTITION BY sr.sales_chan ORDER BY sr.date_sk DESC) AS rn,
           SUM(sr.net_profit) OVER (PARTITION BY sr.sales_chan ORDER BY sr.date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit,
           CASE
               WHEN sr.location_state IS NULL THEN 'UNKNOWN'
               WHEN sr.location_state IN ('CA', 'NY', 'TX') THEN 'HIGH_VALUE_STATE'
               ELSE 'OTHER_STATE'
           END AS state_category,
           (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = sr.date_sk) AS sale_date,
           (SELECT MAX(ss2.ss_ticket_number) FROM store_sales ss2 WHERE ss2.ss_customer_sk = sr.customer_sk) AS max_ticket_number
    FROM sales_raw sr
    LEFT JOIN customer_returns cr ON sr.customer_sk = cr.c_customer_sk
    LEFT JOIN customer_sales cs ON sr.customer_sk = cs.c_customer_sk
    LEFT JOIN customer c ON sr.customer_sk = c.c_customer_sk
    WHERE sr.ext_sales_price > 0
),
aggregated AS (
    SELECT sales_chan,
           date_sk,
           sale_date,
           location_state,
           state_category,
           SUM(ext_sales_price) AS total_ext_sales_price,
           SUM(net_profit) AS total_net_profit,
           MAX(cum_net_profit) AS max_cum_net_profit,
           AVG(return_rate) AS avg_return_rate,
           COUNT(DISTINCT cust_key) AS distinct_customers,
           SUM(CASE WHEN return_rate > 0.5 THEN 1 ELSE 0 END) AS high_return_customers,
           MAX(CASE WHEN rn = 1 THEN net_profit END) AS most_recent_net_profit,
           SUM(CASE WHEN quantity > 0 THEN ext_sales_price / NULLIF(quantity, 0) ELSE 0 END) /
               NULLIF(SUM(CASE WHEN quantity > 0 THEN 1 ELSE 0 END), 0) AS avg_price_per_item,
           CONCAT(sales_chan, '-', COALESCE(location_state, 'XX')) AS channel_state_key,
           MAX(max_ticket_number) AS max_ticket_number_overall
    FROM joined
    GROUP BY sales_chan, date_sk, sale_date, location_state, state_category
    HAVING SUM(ext_sales_price) > 10000
),
final AS (
    SELECT *
    FROM aggregated
    WHERE state_category = 'HIGH_VALUE_STATE'
    UNION ALL
    SELECT *
    FROM aggregated
    WHERE state_category = 'OTHER_STATE' AND total_net_profit > 0
)
SELECT *
FROM final
ORDER BY total_net_profit DESC
LIMIT 100
