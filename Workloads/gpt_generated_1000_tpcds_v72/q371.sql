WITH sales_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_bill_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_addr_sk
    FROM catalog_sales cs
),
agg AS (
    SELECT
        s.s_store_id,
        s.s_city,
        s.s_state,
        SUM(sd.cs_net_paid_inc_tax)                         AS total_sales,
        SUM(cr.cr_return_amount)                            AS total_return_amount,
        SUM(sd.cs_net_profit) - SUM(cr.cr_net_loss) - SUM(sr.sr_net_loss) AS net_income
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c_sr
        ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = c_sr.c_customer_sk
    JOIN sales_data sd
        ON sd.cs_order_number = cr.cr_order_number
       AND sd.cs_item_sk = cr.cr_item_sk
    JOIN customer c_bill
        ON sd.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON sd.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship
        ON sd.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON sd.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer c_refund
        ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE s.s_country = 'United States'
    GROUP BY s.s_store_id, s.s_city, s.s_state
)
SELECT
    a.s_store_id,
    a.s_city,
    a.s_state,
    a.total_sales,
    a.total_return_amount,
    a.net_income,
    CASE WHEN a.net_income > 10000 THEN 'High' ELSE 'Low' END AS profit_category,
    RANK() OVER (ORDER BY a.total_sales DESC)                     AS sales_rank,
    SUM(a.total_sales) OVER (PARTITION BY a.s_state)             AS state_sales_total
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
