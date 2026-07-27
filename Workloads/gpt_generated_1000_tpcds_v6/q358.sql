WITH sales_agg AS (
    SELECT
        d1.d_year,
        ca.ca_state,
        we.web_name,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ws.ws_ext_sales_price) AS web_sales
    FROM catalog_sales cs
    JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d1.d_date_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d1.d_date_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
    WHERE d1.d_year = 2001
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND we.web_market_manager = 'James Brewer'
      AND wp.wp_type = 'home'
      AND wp.wp_char_count > 1000
      AND inv.inv_quantity_on_hand > 0
      AND cs.cs_quantity > 1
      AND ss.ss_quantity > 0
      AND ws.ws_quantity > 0
    GROUP BY GROUPING SETS (
        (d1.d_year, ca.ca_state, we.web_name),
        (d1.d_year, ca.ca_state),
        (d1.d_year),
        ()
    )
)
SELECT
    d_year,
    ca_state,
    web_name,
    catalog_profit,
    store_profit,
    web_profit,
    (catalog_profit + store_profit + web_profit) AS total_profit
FROM sales_agg
WHERE (catalog_profit + store_profit + web_profit) > (
    SELECT AVG(total_profit) FROM (
        SELECT
            SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit
        FROM catalog_sales cs
        JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
        JOIN customer_address ca2 ON cs.cs_bill_addr_sk = ca2.ca_address_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d2.d_date_sk
            AND ss.ss_addr_sk = ca2.ca_address_sk
        JOIN web_sales ws
            ON ws.ws_sold_date_sk = d2.d_date_sk
            AND ws.ws_bill_addr_sk = ca2.ca_address_sk
        WHERE d2.d_year = 2001
          AND ca2.ca_state IN ('CA', 'TX', 'NY')
          AND cs.cs_quantity > 1
          AND ss.ss_quantity > 0
          AND ws.ws_quantity > 0
    ) sub
)
ORDER BY d_year DESC, total_profit DESC
LIMIT 100
