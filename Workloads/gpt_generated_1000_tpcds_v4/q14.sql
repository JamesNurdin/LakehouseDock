WITH sales_agg AS (
    SELECT
        ca.ca_city,
        p.p_promo_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_demo = 'N'
      AND p.p_response_target = 1
      AND ca.ca_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2451448 AND 2452151
    GROUP BY ca.ca_city, p.p_promo_name
    HAVING SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    sa.ca_city,
    sa.p_promo_name,
    sa.total_sales,
    sa.total_profit,
    sa.unique_tickets,
    (sa.total_sales / NULLIF(sa.unique_tickets, 0)) AS avg_sales_per_ticket,
    (SELECT MAX(total_sales) FROM sales_agg) AS max_city_sales
FROM sales_agg sa
WHERE sa.total_profit > 1000
  AND sa.unique_tickets > 10
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_name = sa.p_promo_name
          AND p2.p_discount_active = 'Y'
    )
ORDER BY sa.total_profit DESC, sa.total_sales DESC
LIMIT 100
