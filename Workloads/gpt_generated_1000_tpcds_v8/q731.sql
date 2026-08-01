WITH sales_agg AS (
    SELECT ws_promo_sk,
           SUM(ws_net_profit) AS promo_net_profit,
           COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_ext_ship_cost > 500
    GROUP BY ws_promo_sk
),
returns_agg AS (
    SELECT wr_order_number,
           SUM(wr_refunded_cash) AS total_refunded_cash,
           COUNT(*) AS returns_cnt
    FROM web_returns
    WHERE wr_return_quantity > 1
    GROUP BY wr_order_number
),
common_orders AS (
    SELECT ws_order_number AS order_number
    FROM web_sales
    WHERE ws_quantity > 2
    INTERSECT
    SELECT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 1
),
union_promos_sites AS (
    SELECT p.p_promo_sk AS id,
           p.p_promo_name AS description,
           NULL AS site_sk
    FROM promotion p
    WHERE p.p_channel_event = 'N'
    UNION
    SELECT ws.ws_web_site_sk AS id,
           CAST(ws.ws_order_number AS varchar) AS description,
           ws.ws_web_site_sk AS site_sk
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk = 15
),
base AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        td.t_hour,
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        ca.ca_city,
        ws_site.web_name,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_ext_ship_cost,
        sa.promo_net_profit,
        ra.total_refunded_cash,
        COALESCE(lc.total_promo_cost, 0) AS promo_cost_total,
        (SELECT COUNT(*) FROM common_orders co WHERE co.order_number = ws.ws_order_number) AS is_common_order
    FROM promotion p
    RIGHT JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN sales_agg sa ON sa.ws_promo_sk = p.p_promo_sk
    LEFT JOIN returns_agg ra ON ra.wr_order_number = ws.ws_order_number
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN LATERAL (
        SELECT SUM(p2.p_cost) AS total_promo_cost
        FROM promotion p2
        WHERE p2.p_promo_sk = ws.ws_promo_sk
    ) lc ON TRUE
    WHERE p.p_channel_event = 'N'
      AND td.t_hour BETWEEN 9 AND 17
      AND cust.c_birth_month = 3
      AND ws.ws_ext_ship_cost > 500
      AND EXISTS (SELECT 1 FROM union_promos_sites ups WHERE ups.id = p.p_promo_sk)
)
SELECT
    p_promo_sk,
    p_promo_name,
    web_name,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_net_paid_inc_ship_tax) AS total_net_paid,
    SUM(promo_net_profit) AS total_promo_profit,
    SUM(total_refunded_cash) AS total_refunded,
    SUM(promo_cost_total) AS total_promo_cost,
    SUM(is_common_order) AS common_order_count,
    ROW_NUMBER() OVER (PARTITION BY p_promo_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS promo_rank
FROM base
GROUP BY
    p_promo_sk,
    p_promo_name,
    web_name
HAVING COUNT(DISTINCT ws_order_number) > 5
ORDER BY total_net_paid DESC
LIMIT 100
