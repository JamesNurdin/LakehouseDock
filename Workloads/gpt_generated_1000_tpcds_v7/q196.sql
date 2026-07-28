WITH sales_returns AS (
    SELECT
        s.s_store_id AS store_id,
        c.c_customer_id AS customer_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE
        cs.cs_quantity > 2
        AND cs.cs_sales_price > 50
        AND cs.cs_net_profit > 0
        AND inv.inv_quantity_on_hand > 10
        AND s.s_state = 'CA'
        AND cp.cp_type = 'monthly'
    GROUP BY
        s.s_store_id,
        c.c_customer_id
)
SELECT
    store_id,
    COUNT(*) AS num_customers,
    SUM(total_sales) AS store_sales,
    SUM(total_returns) AS store_returns,
    AVG(total_profit) AS avg_profit_per_customer
FROM sales_returns
GROUP BY store_id
HAVING AVG(total_profit) > 1000
ORDER BY store_sales DESC
LIMIT 100
