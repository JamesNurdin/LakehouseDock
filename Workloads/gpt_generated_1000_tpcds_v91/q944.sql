WITH unioned AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        ca.ca_state AS state,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_current_price > 100
      AND ca.ca_state = 'TX'
      AND cd.cd_marital_status = 'M'
      AND ws.ws_net_paid > 500
    UNION
    SELECT
        c.c_customer_sk AS customer_sk,
        ca.ca_state AS state,
        ws.ws_net_paid AS net_paid,
        ws.ws_ext_sales_price AS ext_sales_price
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    WHERE d_sold.d_year = 2002
      AND i.i_current_price > 150
      AND ca.ca_state = 'PA'
      AND cd.cd_marital_status = 'S'
      AND ws.ws_net_paid > 1000
),
aggregated AS (
    SELECT
        customer_sk,
        state,
        SUM(net_paid) AS total_net_paid,
        SUM(ext_sales_price) AS total_ext_sales_price,
        COUNT(*) AS num_sales
    FROM unioned
    GROUP BY customer_sk, state
    HAVING SUM(net_paid) > 5000
       AND COUNT(*) >= 2
)
SELECT
    customer_sk,
    state,
    total_net_paid,
    total_ext_sales_price,
    num_sales,
    DENSE_RANK() OVER (PARTITION BY state ORDER BY total_net_paid DESC) AS state_customer_rank
FROM aggregated
ORDER BY state, state_customer_rank
