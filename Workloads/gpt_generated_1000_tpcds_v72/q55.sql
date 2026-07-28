WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        c.c_preferred_cust_flag,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_income_band_sk,
        s.s_store_name,
        r.r_reason_desc
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND ca.ca_state IN ('MO', 'PA')
      AND cd.cd_gender = 'M'
      AND d.d_year = 2001
      AND r.r_reason_desc = 'Package was damaged'
),
web_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        we.web_name,
        we.web_tax_percentage,
        w.w_state,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        r2.r_reason_desc AS web_return_reason
    FROM web_sales ws
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
    WHERE we.web_name = 'OnlineStore'
      AND w.w_state = 'CA'
      AND we.web_tax_percentage > 0
)
SELECT
    sd.d_year,
    sd.ca_state,
    sd.s_store_name,
    wd.web_name,
    COALESCE(wd.web_return_reason, 'No Return') AS return_reason,
    SUM(sd.ss_quantity) AS total_store_qty,
    SUM(sd.ss_net_paid) AS total_store_sales,
    SUM(sd.ss_net_profit) AS total_store_profit,
    SUM(COALESCE(wd.wr_return_quantity, 0)) AS total_web_return_qty,
    SUM(COALESCE(wd.wr_net_loss, 0)) AS total_web_return_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT sd.ss_customer_sk) AS distinct_customers,
    AVG(sd.ss_sales_price) AS avg_store_sales_price
FROM sales_data sd
JOIN web_data wd ON wd.ws_item_sk = sd.ss_item_sk
    AND wd.ws_sold_date_sk = sd.ss_sold_date_sk
JOIN inventory i ON i.inv_date_sk = sd.ss_sold_date_sk
    AND i.inv_warehouse_sk = (
        SELECT w_warehouse_sk FROM warehouse WHERE w_state = 'CA' LIMIT 1
    )
GROUP BY
    sd.d_year,
    sd.ca_state,
    sd.s_store_name,
    wd.web_name,
    COALESCE(wd.web_return_reason, 'No Return')
ORDER BY total_store_sales DESC
LIMIT 100
