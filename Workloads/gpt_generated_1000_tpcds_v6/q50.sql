WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_warehouse_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_order_number,
        d.d_year,
        ca.ca_state,
        w.w_state,
        ws.ws_order_number,
        ws.ws_net_paid,
        site.web_state,
        sr.sr_net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_country = 'United States'
      AND w.w_state = 'WA'
      AND cs.cs_quantity > 5
      AND cs.cs_net_profit > (
          SELECT AVG(cs2.cs_net_profit)
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
)
SELECT
    d_year,
    ca_state,
    w_state,
    web_state,
    COUNT(DISTINCT cs_order_number) AS orders_cnt,
    SUM(cs_ext_sales_price) AS total_sales,
    SUM(sr_net_loss) AS total_return_loss,
    AVG(ws_net_paid) AS avg_net_paid,
    MAX(cs_net_profit) AS max_profit,
    MIN(cs_net_profit) AS min_profit
FROM base
GROUP BY d_year, ca_state, w_state, web_state
HAVING SUM(cs_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 100
