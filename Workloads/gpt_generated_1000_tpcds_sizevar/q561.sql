WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_catalog_page_sk,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        cc.cc_name,
        p.p_promo_name,
        cp.cp_catalog_number,
        cp.cp_description
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cp.cp_catalog_number IN (2, 15, 17)
      AND ca_bill.ca_zip LIKE '75___'
      AND cs.cs_ext_sales_price > 1000
),
promo_agg AS (
    SELECT
        cs.cs_promo_sk AS p_promo_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        AVG(cs.cs_ext_sales_price) AS avg_sale_price
    FROM base cs
    GROUP BY cs.cs_promo_sk
),
overall AS (
    SELECT AVG(total_profit) AS avg_total_profit FROM promo_agg
)
SELECT
    p.p_promo_name,
    pa.total_profit,
    rn,
    extra.adjusted_profit
FROM (
    SELECT p_promo_sk, total_profit,
           ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
    FROM promo_agg
) pa
JOIN promotion p ON pa.p_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
    SELECT pa.total_profit * 0.95 AS adjusted_profit
) AS extra ON TRUE
WHERE pa.total_profit > (SELECT avg_total_profit FROM overall)

UNION

SELECT
    p.p_promo_name,
    pa.total_profit,
    rn,
    extra.adjusted_profit
FROM (
    SELECT p_promo_sk, total_profit,
           ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
    FROM promo_agg
) pa
JOIN promotion p ON pa.p_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
    SELECT pa.total_profit * 0.95 AS adjusted_profit
) AS extra ON TRUE
WHERE pa.total_profit = (SELECT avg_total_profit FROM overall)

EXCEPT

SELECT
    p.p_promo_name,
    pa.total_profit,
    rn,
    extra.adjusted_profit
FROM (
    SELECT p_promo_sk, total_profit,
           ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
    FROM promo_agg
) pa
JOIN promotion p ON pa.p_promo_sk = p.p_promo_sk
LEFT JOIN LATERAL (
    SELECT pa.total_profit * 0.95 AS adjusted_profit
) AS extra ON TRUE
WHERE pa.total_profit < (SELECT avg_total_profit FROM overall)

ORDER BY total_profit DESC
LIMIT 100
