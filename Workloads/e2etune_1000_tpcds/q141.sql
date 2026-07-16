WITH promo_sales AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        ca_bill.ca_country AS bill_country,
        ca_ship.ca_country AS ship_country,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS total_orders,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE p.p_discount_active = 'Y'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
      AND cs.cs_net_profit > 0
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_channel_tv, ca_bill.ca_country, ca_ship.ca_country
    HAVING SUM(cs.cs_net_profit) > 10000
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_profit DESC) AS profit_rank
    FROM promo_sales
)
SELECT
    p_promo_id,
    p_promo_name,
    bill_country,
    ship_country,
    total_profit,
    total_orders,
    avg_discount,
    distinct_customers,
    profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY total_profit DESC
LIMIT 200
