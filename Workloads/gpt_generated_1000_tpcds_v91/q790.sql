WITH filtered_sales AS (
    SELECT
        cs_item_sk,
        cs_order_number,
        cs_net_paid,
        cs_promo_sk,
        cs_bill_customer_sk,
        cs_ship_customer_sk,
        cs_bill_addr_sk,
        cs_ship_addr_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
),
max_promo AS (
    SELECT p_item_sk AS i_item_sk,
           MAX(p_cost) AS max_promo_cost
    FROM promotion
    GROUP BY p_item_sk
)
SELECT
    i.i_item_sk,
    i.i_category,
    i.i_class,
    s.s_state,
    SUM(cs.cs_net_paid) AS total_sales_paid,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    COUNT(DISTINCT c_bill.c_customer_id) AS distinct_bill_customers,
    MAX(max_p.max_promo_cost) AS max_promotion_cost,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_net_loss > 0
    ) AS num_returns_with_loss
FROM item i
JOIN filtered_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer c_sr
    ON sr.sr_customer_sk = c_sr.c_customer_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN max_promo max_p
    ON max_p.i_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
GROUP BY CUBE (i.i_item_sk, i.i_category, i.i_class, s.s_state)
ORDER BY i.i_item_sk, i.i_category, i.i_class, s.s_state
LIMIT 100
