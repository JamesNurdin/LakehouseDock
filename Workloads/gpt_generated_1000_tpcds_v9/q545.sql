WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        r.r_reason_desc,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_size,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_vehicle_count,
        s.s_store_name,
        s.s_state,
        t.t_hour,
        t.t_meal_time,
        ws.ws_coupon_amt,
        ws.ws_ext_tax,
        ws.ws_net_paid AS ws_net_paid,
        w.w_warehouse_name,
        w.w_state AS warehouse_state
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_category = 'Sports'
      AND i.i_brand = 'Brand#45'
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
      AND t.t_hour BETWEEN 9 AND 17
      AND ws.ws_coupon_amt > 200
      AND cd.cd_purchase_estimate > 5000
      AND hd.hd_vehicle_count >= 2
)
SELECT
    i_category,
    i_brand,
    s_state,
    warehouse_state,
    t_hour,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
    AVG(ws_coupon_amt) AS avg_coupon_amt,
    MIN(ss_net_paid) AS min_net_paid,
    MAX(ss_net_paid) AS max_net_paid
FROM base_sales
WHERE NOT EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_item_sk = base_sales.ss_item_sk
)
GROUP BY i_category, i_brand, s_state, warehouse_state, t_hour
ORDER BY total_sales DESC
LIMIT 100
