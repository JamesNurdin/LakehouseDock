WITH sales AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cs.cs_bill_customer_sk AS bill_customer_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt
    FROM catalog_sales cs
),
web AS (
    SELECT
        ws.ws_promo_sk AS promo_sk,
        ws.ws_ship_mode_sk AS ship_mode_sk,
        ws.ws_bill_customer_sk AS bill_customer_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt
    FROM web_sales ws
),
sales_union AS (
    SELECT * FROM sales
    UNION ALL
    SELECT * FROM web
),
returns AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        cs.cs_ship_mode_sk AS ship_mode_sk,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
),
agg_sales AS (
    SELECT
        su.promo_sk,
        su.ship_mode_sk,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        SUM(su.discount_amt) AS total_discount,
        COUNT(DISTINCT su.bill_customer_sk) AS distinct_customers
    FROM sales_union su
    GROUP BY su.promo_sk, su.ship_mode_sk
),
agg_returns AS (
    SELECT
        r.promo_sk,
        r.ship_mode_sk,
        SUM(r.net_loss) AS total_return_loss
    FROM returns r
    GROUP BY r.promo_sk, r.ship_mode_sk
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    COALESCE(a.total_net_paid, 0) AS total_net_paid,
    COALESCE(a.total_net_profit, 0) AS total_net_profit,
    COALESCE(a.total_discount, 0) AS total_discount,
    COALESCE(a.distinct_customers, 0) AS distinct_customers,
    COALESCE(r.total_return_loss, 0) AS total_return_loss
FROM agg_sales a
LEFT JOIN agg_returns r
    ON a.promo_sk = r.promo_sk
    AND a.ship_mode_sk = r.ship_mode_sk
JOIN promotion p
    ON a.promo_sk = p.p_promo_sk
JOIN ship_mode sm
    ON a.ship_mode_sk = sm.sm_ship_mode_sk
WHERE p.p_discount_active = 'Y'
ORDER BY total_net_profit DESC
LIMIT 100
