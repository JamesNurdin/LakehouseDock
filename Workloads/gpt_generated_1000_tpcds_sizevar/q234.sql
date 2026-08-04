WITH
    store_sales_agg AS (
        SELECT
            ss.ss_addr_sk AS addr_sk,
            SUM(ss.ss_net_paid) AS total_store_paid,
            SUM(ss.ss_net_profit) AS total_store_profit
        FROM tpcds.store_sales ss
        WHERE ss.ss_ext_tax > 50.0
          AND ss.ss_quantity >= 2
        GROUP BY ss.ss_addr_sk
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_bill_addr_sk AS addr_sk,
            SUM(ws.ws_net_paid) AS total_web_paid,
            SUM(ws.ws_net_profit) AS total_web_profit
        FROM tpcds.web_sales ws
        WHERE ws.ws_ext_ship_cost > 200.0
          AND ws.ws_quantity >= 1
        GROUP BY ws.ws_bill_addr_sk
    ),
    catalog_sales_agg AS (
        SELECT
            cs.cs_bill_addr_sk AS addr_sk,
            SUM(cs.cs_net_paid) AS total_catalog_paid,
            SUM(cs.cs_net_profit) AS total_catalog_profit
        FROM tpcds.catalog_sales cs
        WHERE cs.cs_ext_tax > 100.0
        GROUP BY cs.cs_bill_addr_sk
    ),
    store_returns_agg AS (
        SELECT
            sr.sr_addr_sk AS addr_sk,
            SUM(sr.sr_net_loss) AS total_return_loss
        FROM tpcds.store_returns sr
        WHERE sr.sr_return_quantity > 0
        GROUP BY sr.sr_addr_sk
    ),
    store_catalog_common AS (
        SELECT addr_sk FROM store_sales_agg
        INTERSECT
        SELECT addr_sk FROM catalog_sales_agg
    ),
    combined_union AS (
        SELECT
            ss.addr_sk,
            ss.total_store_paid AS total_paid,
            ss.total_store_profit AS total_profit,
            COALESCE(sr.total_return_loss, 0) AS total_return_loss
        FROM store_sales_agg ss
        LEFT JOIN store_returns_agg sr ON ss.addr_sk = sr.addr_sk
        UNION DISTINCT
        SELECT
            ws.addr_sk,
            ws.total_web_paid AS total_paid,
            ws.total_web_profit AS total_profit,
            0.0 AS total_return_loss
        FROM web_sales_agg ws
    )
SELECT
    ca.ca_state,
    ca.ca_city,
    cu.addr_sk,
    SUM(cu.total_paid) AS sum_total_paid,
    SUM(cu.total_profit) AS sum_total_profit,
    SUM(cu.total_return_loss) AS sum_total_return_loss,
    SUM(COALESCE(cs.total_catalog_paid, 0)) AS sum_catalog_paid,
    SUM(COALESCE(cs.total_catalog_profit, 0)) AS sum_catalog_profit,
    COUNT(DISTINCT cu.addr_sk) AS address_cnt
FROM combined_union cu
JOIN tpcds.customer_address ca ON ca.ca_address_sk = cu.addr_sk
LEFT JOIN catalog_sales_agg cs ON cs.addr_sk = cu.addr_sk
JOIN store_catalog_common scc ON scc.addr_sk = cu.addr_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'IL')
  AND ca.ca_gmt_offset BETWEEN -8.00 AND -5.00
GROUP BY ca.ca_state, ca.ca_city, cu.addr_sk
ORDER BY sum_total_paid DESC
LIMIT 100
