WITH joined AS (
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_ext_sales_price AS cs_ext_sales_price,
        cs.cs_coupon_amt AS cs_coupon_amt,
        cs.cs_quantity AS cs_quantity,
        cs.cs_ext_ship_cost AS cs_ext_ship_cost,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_coupon_amt AS ws_coupon_amt,
        ws.ws_quantity AS ws_quantity,
        ws.ws_ext_ship_cost AS ws_ext_ship_cost,
        wr.wr_net_loss AS wr_net_loss,
        wr.wr_return_amt AS wr_return_amt,
        td.t_hour,
        td.t_minute,
        td.t_sub_shift,
        ca_bill.ca_city AS bill_city,
        ca_bill.ca_state AS bill_state,
        ca_bill.ca_location_type AS bill_location_type,
        ca_ship.ca_city AS ship_city,
        ca_ship.ca_state AS ship_state,
        ca_ship.ca_location_type AS ship_location_type,
        ca_refunded.ca_city AS refunded_city,
        ca_returning.ca_city AS returning_city,
        cc.cc_name AS call_center_name,
        cc.cc_class AS call_center_class
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
                         AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND ca_bill.ca_location_type = 'apartment'
      AND cs.cs_coupon_amt > 0
)
SELECT
    order_number,
    call_center_name,
    call_center_class,
    bill_city,
    ship_city,
    refunded_city,
    returning_city,
    t_hour,
    t_sub_shift,
    cs_ext_sales_price,
    ws_ext_sales_price,
    (cs_ext_sales_price + ws_ext_sales_price) AS total_ext_sales_price,
    CASE
        WHEN (cs_net_profit + ws_net_profit) >= 0 THEN 'profitable'
        ELSE 'unprofitable'
    END AS profit_status,
    RANK() OVER (PARTITION BY call_center_name ORDER BY (cs_net_profit + ws_net_profit) DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY t_sub_shift ORDER BY (cs_ext_sales_price + ws_ext_sales_price) DESC) AS sales_row_num
FROM joined
ORDER BY profit_rank ASC, total_ext_sales_price DESC
LIMIT 100
