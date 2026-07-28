WITH sales_data AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        ss.ss_quantity AS sales_quantity,
        ss.ss_sales_price,
        sr.sr_return_amt
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
),
aggregated AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        st.s_store_name,
        hd_sales.hd_buy_potential,
        SUM(sd.ss_net_paid) AS total_net_paid,
        SUM(COALESCE(sd.sr_net_loss, 0)) AS total_net_loss,
        SUM(inv_a.inv_quantity_on_hand) AS inv_qty_warehouse_a,
        SUM(inv_b.inv_quantity_on_hand) AS inv_qty_warehouse_b,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM sales_data sd
    JOIN item i
        ON sd.ss_item_sk = i.i_item_sk
    JOIN store st
        ON sd.ss_store_sk = st.s_store_sk
    JOIN customer cust_sales
        ON sd.ss_customer_sk = cust_sales.c_customer_sk
    JOIN household_demographics hd_sales
        ON sd.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN inventory inv_a
        ON i.i_item_sk = inv_a.inv_item_sk
    JOIN inventory inv_b
        ON i.i_item_sk = inv_b.inv_item_sk
       AND inv_b.inv_warehouse_sk <> inv_a.inv_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN customer cust_bill
        ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer cust_ship
        ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE i.i_current_price > 20
      AND hd_sales.hd_income_band_sk = 14
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        st.s_store_name,
        hd_sales.hd_buy_potential
    HAVING SUM(sd.ss_net_paid) > 1000
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.s_store_name,
    a.hd_buy_potential,
    a.total_net_paid,
    a.total_net_loss,
    a.inv_qty_warehouse_a,
    a.inv_qty_warehouse_b,
    a.web_orders,
    ROW_NUMBER() OVER (PARTITION BY a.i_item_id ORDER BY a.total_net_paid DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_net_paid DESC
LIMIT 100
