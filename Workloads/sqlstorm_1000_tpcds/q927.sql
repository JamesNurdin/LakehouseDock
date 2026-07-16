WITH sales AS (
    SELECT 'Store' AS channel,
           d.d_year AS sales_year,
           d.d_moy AS sales_month,
           s.s_state AS state,
           i.i_category AS category,
           i.i_class AS class,
           ss.ss_net_paid AS net_paid,
           sr.sr_net_loss AS net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_store_sk = sr.sr_store_sk
        AND ss.ss_item_sk = sr.sr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT 'Catalog' AS channel,
           d.d_year AS sales_year,
           d.d_moy AS sales_month,
           cc.cc_state AS state,
           i.i_category AS category,
           i.i_class AS class,
           cs.cs_net_paid AS net_paid,
           cr.cr_net_loss AS net_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002

    UNION ALL

    SELECT 'Web' AS channel,
           d.d_year AS sales_year,
           d.d_moy AS sales_month,
           ca.ca_state AS state,
           i.i_category AS category,
           i.i_class AS class,
           ws.ws_net_paid AS net_paid,
           wr.wr_net_loss AS net_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
)
SELECT channel,
       sales_year,
       sales_month,
       state,
       category,
       class,
       SUM(net_paid) AS total_net_paid,
       SUM(COALESCE(net_loss, 0)) AS total_net_loss,
       SUM(net_paid) - SUM(COALESCE(net_loss, 0)) AS net_revenue
FROM sales
GROUP BY channel, sales_year, sales_month, state, category, class
ORDER BY channel, sales_year, sales_month, state, category, class
