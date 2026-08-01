WITH sales_with_promo AS (
    SELECT
        ws.ws_order_number,
        ca.ca_county,
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
        SUBSTRING(ca.ca_zip, 1, 5) AS zip_prefix,
        p.p_promo_id,
        REGEXP_EXTRACT(p.p_promo_id, '^([A-Z]+)') AS promo_prefix,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        CASE
            WHEN ws.ws_net_profit > 0 THEN 'Profit'
            WHEN ws.ws_net_profit = 0 THEN 'BreakEven'
            ELSE 'Loss'
        END AS profit_category
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(p.p_promo_id, '^AAAA')
      AND ca.ca_state LIKE 'C%'
)
SELECT
    ag.ca_county,
    ag.profit_category,
    ag.promo_prefix,
    ag.total_sales,
    ag.total_profit,
    ag.avg_profit,
    ag.orders,
    ROW_NUMBER() OVER (PARTITION BY ag.ca_county ORDER BY ag.total_profit DESC) AS rn
FROM (
    SELECT
        sp.ca_county,
        sp.profit_category,
        sp.promo_prefix,
        SUM(sp.ws_ext_sales_price) AS total_sales,
        SUM(sp.ws_net_profit) AS total_profit,
        AVG(sp.ws_net_profit) AS avg_profit,
        COUNT(DISTINCT sp.ws_order_number) AS orders
    FROM sales_with_promo sp
    WHERE sp.ca_county IN (
        SELECT ca2.ca_county
        FROM catalog_returns cr2
        JOIN customer_address ca2 ON cr2.cr_refunded_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_city LIKE 'A%'
    )
    GROUP BY sp.ca_county, sp.profit_category, sp.promo_prefix
    HAVING SUM(sp.ws_ext_sales_price) > 10000
) AS ag
ORDER BY ag.total_profit DESC
LIMIT 100
