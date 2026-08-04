WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    GROUP BY cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_warehouse_sk
),
common_items AS (
    SELECT cs_item_sk FROM catalog_sales
    INTERSECT
    SELECT ss_item_sk FROM store_sales
),
cs_exclusive AS (
    SELECT cs_item_sk FROM catalog_sales
    EXCEPT
    SELECT ws_item_sk FROM web_sales
)
SELECT
    i.i_item_id,
    d1.d_date,
    CASE
        WHEN cs_agg.total_profit > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_category,
    cs_agg.total_sales,
    cs_agg.avg_discount,
    cs_agg.total_profit,
    p.p_promo_name,
    w.w_warehouse_name,
    c_bill.c_customer_id AS billing_customer_id,
    c_ship.c_customer_id AS shipping_customer_id,
    s.s_store_name,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    ws.ws_net_profit AS web_net_profit
FROM cs_agg
JOIN common_items ci
    ON cs_agg.cs_item_sk = ci.cs_item_sk
LEFT JOIN cs_exclusive cex
    ON cs_agg.cs_item_sk = cex.cs_item_sk
JOIN date_dim d1
    ON cs_agg.cs_sold_date_sk = d1.d_date_sk
JOIN time_dim t1
    ON cs_agg.cs_sold_time_sk = t1.t_time_sk
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN promotion p
    ON cs_agg.cs_promo_sk = p.p_promo_sk
JOIN customer c_bill
    ON cs_agg.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs_agg.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = cs_agg.cs_item_sk
JOIN date_dim d2
    ON cr.cr_returned_date_sk = d2.d_date_sk
JOIN time_dim t2
    ON cr.cr_returned_time_sk = t2.t_time_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d1.d_date_sk
   AND ss.ss_item_sk = cs_agg.cs_item_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
FULL OUTER JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d1.d_date_sk
   AND ws.ws_item_sk = i.i_item_sk
   AND ws.ws_bill_customer_sk = c_bill.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN inventory inv
    ON inv.inv_date_sk = d1.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
   AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE ci.cs_item_sk IS NOT NULL
ORDER BY cs_agg.total_profit DESC
OFFSET 0 LIMIT 100
