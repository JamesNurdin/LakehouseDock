WITH sales_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        c_bill.c_first_name,
        c_bill.c_last_name,
        c_bill.c_email_address,
        cd_bill.cd_gender,
        hd_bill.hd_income_band_sk,
        t.t_hour,
        t.t_meal_time,
        ws.ws_web_site_sk,
        wsite.web_name,
        wsite.web_gmt_offset,
        wsite.web_tax_percentage,
        inv.inv_quantity_on_hand,
        CASE
            WHEN ws.ws_net_paid > 0 THEN ws.ws_net_profit / ws.ws_net_paid
            ELSE 0
        END AS profit_margin,
        (SELECT avg(inv2.inv_quantity_on_hand) FROM inventory inv2 WHERE inv2.inv_item_sk = ws.ws_item_sk) AS avg_inventory_qty,
        ws.ws_ship_addr_sk
    FROM
        web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
        JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        c_bill.c_birth_month = 12
        AND c_bill.c_preferred_cust_flag = 'Y'
        AND ca_bill.ca_state = 'CA'
        AND i.i_category = 'Electronics'
        AND t.t_hour BETWEEN 9 AND 12
        AND wsite.web_gmt_offset = -5.00
        AND ws.ws_quantity > 5
        AND ws.ws_ext_sales_price > 100
        AND inv.inv_quantity_on_hand > 0
)
SELECT
    sd.ws_order_number,
    sd.c_first_name,
    sd.c_last_name,
    sd.c_email_address,
    sd.i_item_id,
    sd.i_product_name,
    sd.i_category,
    sd.ws_quantity,
    sd.ws_ext_sales_price,
    sd.ws_net_paid,
    sd.profit_margin,
    sd.avg_inventory_qty,
    sd.web_name,
    RANK() OVER (PARTITION BY sd.web_name ORDER BY sd.ws_net_paid DESC) AS sales_rank,
    ROW_NUMBER() OVER (ORDER BY sd.ws_net_paid DESC) AS overall_rank
FROM
    sales_detail sd
WHERE
    EXISTS (
        SELECT 1 FROM customer_address ca2
        WHERE ca2.ca_address_sk = sd.ws_ship_addr_sk
          AND ca2.ca_city = 'Dallas'
    )
ORDER BY
    sd.ws_net_paid DESC,
    sales_rank
LIMIT 100
