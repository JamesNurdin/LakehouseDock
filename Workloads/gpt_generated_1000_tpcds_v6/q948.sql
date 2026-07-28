WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_net_profit)          AS order_net_profit,
        SUM(cs.cs_ext_sales_price)    AS order_sales,
        SUM(cs.cs_quantity)           AS order_qty
    FROM catalog_sales cs
    GROUP BY
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_catalog_page_sk
)
SELECT
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_brand,
    CASE WHEN SUM(sa.order_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUM(sa.order_net_profit) AS total_net_profit,
    SUM(sa.order_sales)      AS total_sales,
    COUNT(DISTINCT sa.cs_order_number) AS orders_cnt,
    (SELECT AVG(inner_sa.order_net_profit) FROM sales_agg inner_sa) AS avg_order_profit_all
FROM sales_agg sa
JOIN catalog_page cp
    ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer bill_cust
    ON sa.cs_bill_customer_sk = bill_cust.c_customer_sk
JOIN customer ship_cust
    ON sa.cs_ship_customer_sk = ship_cust.c_customer_sk
JOIN customer_address bill_addr
    ON sa.cs_bill_addr_sk = bill_addr.ca_address_sk
JOIN customer_address ship_addr
    ON sa.cs_ship_addr_sk = ship_addr.ca_address_sk
JOIN customer_demographics bill_demo
    ON sa.cs_bill_cdemo_sk = bill_demo.cd_demo_sk
JOIN customer_demographics ship_demo
    ON sa.cs_ship_cdemo_sk = ship_demo.cd_demo_sk
JOIN date_dim d_sold
    ON sa.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON sa.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON sa.cs_item_sk = i.i_item_sk
LEFT JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_web_open
    ON d_web_open.d_date_sk = d_sold.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_web_open.d_date_sk
GROUP BY GROUPING SETS (
    (s.s_store_name, d_sold.d_year, d_sold.d_month_seq, i.i_brand),
    (s.s_store_name, i.i_brand),
    (d_sold.d_year, d_sold.d_month_seq, i.i_brand),
    (i.i_brand),
    ()
)
HAVING SUM(sa.order_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
