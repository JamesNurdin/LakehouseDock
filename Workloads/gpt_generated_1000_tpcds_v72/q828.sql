WITH unified AS (
    SELECT
        s.s_store_name,
        d.d_year,
        sm.sm_type,
        cd_bill.cd_gender,
        SUM(cs.cs_net_profit + ws.ws_net_profit + ss.ss_net_profit - sr.sr_net_loss - wr.wr_net_loss) AS total_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    -- Web sales linked through the same date and time dimensions and the same dimension tables
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
       AND ws.ws_sold_time_sk = t.t_time_sk
       AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
       AND ws.ws_ship_customer_sk = c_ship.c_customer_sk
       AND ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
       AND ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
       AND ws.ws_bill_addr_sk = ca_bill.ca_address_sk
       AND ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    -- Store dimension
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    -- Store sales
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_sold_time_sk = t.t_time_sk
       AND ss.ss_customer_sk = c_bill.c_customer_sk
       AND ss.ss_cdemo_sk = cd_bill.cd_demo_sk
       AND ss.ss_addr_sk = ca_bill.ca_address_sk
       AND ss.ss_store_sk = s.s_store_sk
    -- Store returns linked to store sales
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
       AND sr.sr_return_time_sk = t.t_time_sk
       AND sr.sr_customer_sk = c_bill.c_customer_sk
       AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
       AND sr.sr_addr_sk = ca_bill.ca_address_sk
       AND sr.sr_store_sk = s.s_store_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
    -- Web returns linked to web sales
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_refunded_customer_sk = c_bill.c_customer_sk
       AND wr.wr_refunded_cdemo_sk = cd_bill.cd_demo_sk
       AND wr.wr_refunded_addr_sk = ca_bill.ca_address_sk
       AND wr.wr_returning_customer_sk = c_ship.c_customer_sk
       AND wr.wr_returning_cdemo_sk = cd_ship.cd_demo_sk
       AND wr.wr_returning_addr_sk = ca_ship.ca_address_sk
       AND wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND cd_bill.cd_gender = 'M'
    GROUP BY s.s_store_name, d.d_year, sm.sm_type, cd_bill.cd_gender
)
SELECT s_store_name,
       d_year,
       sm_type,
       cd_gender,
       total_profit
FROM unified
ORDER BY total_profit DESC
LIMIT 100
