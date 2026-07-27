WITH catalog_agg AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk AS cust_bill_sk,
        cs.cs_ship_customer_sk AS cust_ship_sk,
        cs.cs_bill_addr_sk   AS addr_bill_sk,
        cs.cs_ship_addr_sk   AS addr_ship_sk,
        cs.cs_bill_hdemo_sk  AS hd_bill_sk,
        cs.cs_ship_hdemo_sk  AS hd_ship_sk,
        cs.cs_item_sk        AS item_sk,
        cs.cs_promo_sk       AS promo_sk,
        cs.cs_order_number,
        cs.cs_net_profit
    FROM catalog_sales cs
),
catalog_summary AS (
    SELECT
        ca.cust_bill_sk,
        ca.item_sk,
        ca.promo_sk,
        SUM(ca.cs_net_profit)                     AS catalog_net_profit,
        COUNT(DISTINCT ca.cs_order_number)        AS catalog_order_cnt,
        MAX(ca.cust_ship_sk)                     AS cust_ship_sk,
        MAX(ca.addr_bill_sk)                     AS addr_bill_sk,
        MAX(ca.addr_ship_sk)                     AS addr_ship_sk,
        MAX(ca.hd_bill_sk)                       AS hd_bill_sk,
        MAX(ca.hd_ship_sk)                       AS hd_ship_sk
    FROM catalog_agg ca
    GROUP BY ca.cust_bill_sk, ca.item_sk, ca.promo_sk
),
web_summary AS (
    SELECT
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_promo_sk,
        SUM(ws.ws_net_profit)            AS web_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk, ws.ws_item_sk, ws.ws_promo_sk
)
SELECT
    cust.c_customer_id,
    i.i_brand,
    promo.p_promo_name,
    promo2.p_discount_active,
    cs_sum.catalog_net_profit,
    ws_sum.web_net_profit,
    cs_sum.catalog_order_cnt,
    ws_sum.web_order_cnt
FROM catalog_summary cs_sum
JOIN customer cust
    ON cs_sum.cust_bill_sk = cust.c_customer_sk
JOIN item i
    ON cs_sum.item_sk = i.i_item_sk
JOIN promotion promo
    ON cs_sum.promo_sk = promo.p_promo_sk
JOIN promotion promo2
    ON i.i_item_sk = promo2.p_item_sk
JOIN customer_address addr_bill
    ON cs_sum.addr_bill_sk = addr_bill.ca_address_sk
JOIN customer_address addr_ship
    ON cs_sum.addr_ship_sk = addr_ship.ca_address_sk
JOIN household_demographics hd_bill
    ON cs_sum.hd_bill_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON cs_sum.hd_ship_sk = hd_ship.hd_demo_sk
JOIN web_summary ws_sum
    ON ws_sum.ws_bill_customer_sk = cust.c_customer_sk
   AND ws_sum.ws_item_sk = i.i_item_sk
   AND ws_sum.ws_promo_sk = promo.p_promo_sk
GROUP BY
    cust.c_customer_id,
    i.i_brand,
    promo.p_promo_name,
    promo2.p_discount_active,
    cs_sum.catalog_net_profit,
    ws_sum.web_net_profit,
    cs_sum.catalog_order_cnt,
    ws_sum.web_order_cnt
ORDER BY cs_sum.catalog_net_profit DESC
LIMIT 100
