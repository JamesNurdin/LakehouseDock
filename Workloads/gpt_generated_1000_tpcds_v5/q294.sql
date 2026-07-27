WITH catalog_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        cs.cs_sold_date_sk,
        ca.ca_state,
        cd.cd_gender,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_quantity) AS catalog_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cs.cs_warehouse_sk, cs.cs_sold_date_sk, ca.ca_state, cd.cd_gender
),
web_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        ws.ws_sold_date_sk,
        site.web_name,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM web_sales ws
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    GROUP BY ws.ws_warehouse_sk, ws.ws_sold_date_sk, site.web_name
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    ca_state,
    cd_gender,
    web_name,
    SUM(COALESCE(ca.catalog_net_paid, 0)) AS total_catalog_net,
    SUM(COALESCE(wa.web_net_paid, 0)) AS total_web_net,
    SUM(COALESCE(sr.sr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(i.inv_quantity_on_hand, 0)) AS total_inventory_on_hand,
    COUNT(DISTINCT ca.catalog_orders) AS distinct_catalog_orders,
    COUNT(DISTINCT wa.web_orders) AS distinct_web_orders
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
    ON ca.cs_warehouse_sk = wa.ws_warehouse_sk
   AND ca.cs_sold_date_sk = wa.ws_sold_date_sk
JOIN warehouse w
    ON COALESCE(ca.cs_warehouse_sk, wa.ws_warehouse_sk) = w.w_warehouse_sk
LEFT OUTER JOIN inventory i
    ON w.w_warehouse_sk = i.inv_warehouse_sk
   AND COALESCE(ca.cs_sold_date_sk, wa.ws_sold_date_sk) = i.inv_date_sk
JOIN date_dim d
    ON COALESCE(ca.cs_sold_date_sk, wa.ws_sold_date_sk) = d.d_date_sk
JOIN store_returns sr
    ON d.d_date_sk = sr.sr_returned_date_sk
WHERE
    d.d_year = 2001
    AND ca_state = 'CA'
    AND w.w_city = 'Los Angeles'
GROUP BY
    w.w_warehouse_name,
    d.d_year,
    ca_state,
    cd_gender,
    web_name
ORDER BY total_catalog_net DESC
LIMIT 100
