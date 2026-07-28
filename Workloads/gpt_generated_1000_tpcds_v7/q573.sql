WITH sales_agg AS (
    SELECT
        d_cs.d_year               AS year,
        sm.sm_type                AS ship_type,
        i.i_category              AS category,
        SUM(cs.cs_net_paid)       AS sum_cs_net_paid,
        SUM(ss.ss_net_paid)       AS sum_ss_net_paid,
        SUM(ws.ws_net_paid)       AS sum_ws_net_paid
    FROM catalog_sales cs
    JOIN date_dim d_cs               ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs               ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN ship_mode sm                ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i                      ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c_bill            ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill   ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship            ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_ship   ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk

    -- store_sales and its dimensions
    JOIN store_sales ss               ON ss.ss_item_sk = cs.cs_item_sk                     -- share the same item for a realistic join path
    JOIN date_dim d_ss               ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss               ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer c_ss               ON ss.ss_customer_sk = c_ss.c_customer_sk
    JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN customer_address ca_ss      ON ss.ss_addr_sk = ca_ss.ca_address_sk

    -- store_returns and its dimensions
    JOIN store_returns sr            ON sr.sr_ticket_number = ss.ss_ticket_number
                                      AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_sr               ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN time_dim t_sr               ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN reason r_sr                 ON sr.sr_reason_sk = r_sr.r_reason_sk

    -- web_sales and its dimensions (web_page is left‑joined to illustrate outer‑join handling)
    JOIN web_sales ws                ON ws.ws_item_sk = cs.cs_item_sk
    JOIN date_dim d_ws               ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN time_dim t_ws               ON ws.ws_sold_time_sk = t_ws.t_time_sk
    JOIN ship_mode sm_ws             ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite              ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN customer c_ws               ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN customer_address ca_ws      ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk

    -- web_returns and its dimensions
    JOIN web_returns wr              ON wr.wr_order_number = ws.ws_order_number
                                      AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d_wr               ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr               ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r_wr                 ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN web_page wp_wr              ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk

    WHERE d_cs.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND ca_bill.ca_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r_sr.r_reason_desc = 'Damaged'
      AND ws.ws_quantity > 0
      AND cs.cs_quantity > 1
      AND ss.ss_quantity >= 1
      AND wsite.web_country = 'United States'
    GROUP BY d_cs.d_year, sm.sm_type, i.i_category
),
 total_per_year AS (
    SELECT
        year,
        (sum_cs_net_paid + sum_ss_net_paid + sum_ws_net_paid) AS total_net_paid
    FROM sales_agg
)
SELECT
    year,
    AVG(total_net_paid) AS avg_total_net_paid
FROM total_per_year
GROUP BY year
HAVING AVG(total_net_paid) > 1000
ORDER BY year
