WITH sales_returns AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        i.i_category,
        i.i_brand,
        promo.p_promo_name AS promo_name,
        cc.cc_name AS call_center_name,
        td_sold.t_hour AS sold_hour,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        td_return.t_hour AS return_hour,
        ca_refunded.ca_state AS refunded_state,
        ca_returning.ca_state AS returning_state,
        i_ret.i_brand AS return_item_brand,
        cc_ret.cc_name AS return_call_center_name,
        CASE
            WHEN cr.cr_return_quantity IS NULL THEN 'No Return'
            WHEN cr.cr_return_quantity > cs.cs_quantity THEN 'Partial Over Return'
            ELSE 'Returned'
        END AS return_status
    FROM catalog_sales cs
    JOIN time_dim td_sold
        ON cs.cs_sold_time_sk = td_sold.t_time_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion promo
        ON cs.cs_promo_sk = promo.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN time_dim td_return
        ON cr.cr_returned_time_sk = td_return.t_time_sk
    LEFT JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    LEFT JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    LEFT JOIN item i_ret
        ON cr.cr_item_sk = i_ret.i_item_sk
    LEFT JOIN call_center cc_ret
        ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
)
SELECT
    bill_state,
    ship_state,
    i_category,
    i_brand,
    promo_name,
    call_center_name,
    sold_hour,
    COUNT(*) AS orders,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(cs_net_profit) AS total_profit,
    SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
    COUNT(DISTINCT CASE WHEN return_status = 'Returned' THEN cs_order_number END) AS returned_orders,
    AVG(CASE WHEN return_status = 'No Return' THEN cs_net_paid END) AS avg_paid_no_return
FROM sales_returns
GROUP BY
    bill_state,
    ship_state,
    i_category,
    i_brand,
    promo_name,
    call_center_name,
    sold_hour
ORDER BY total_net_paid DESC
LIMIT 100
