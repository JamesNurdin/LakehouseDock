WITH sub_a AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       t.channel_word,
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_net_paid_inc_ship_tax
   FROM tpcds.promotion p
   JOIN tpcds.web_sales ws
       ON p.p_promo_sk = ws.ws_promo_sk
   CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t (channel_word)
   WHERE ws.ws_ship_date_sk BETWEEN 2452600 AND 2452800
     AND p.p_purpose = 'Unknown'
),
sub_b AS (
   SELECT
       p.p_promo_sk,
       p.p_promo_name,
       t.channel_word,
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_net_paid_inc_ship_tax
   FROM tpcds.promotion p
   JOIN tpcds.web_sales ws
       ON p.p_promo_sk = ws.ws_promo_sk
   CROSS JOIN UNNEST(split(p.p_channel_details, ',')) AS t (channel_word)
   WHERE ws.ws_net_paid_inc_ship_tax > 1000
     AND p.p_channel_details LIKE '%Excellent%'
),
intersected AS (
   SELECT * FROM sub_a
   INTERSECT
   SELECT * FROM sub_b
),
agg AS (
   SELECT
       p_promo_sk,
       p_promo_name,
       COUNT(DISTINCT ws_order_number) AS distinct_orders,
       COUNT(DISTINCT ws_item_sk) AS distinct_items
   FROM intersected
   GROUP BY p_promo_sk, p_promo_name
),
ranked AS (
   SELECT
       p_promo_sk,
       p_promo_name,
       distinct_orders,
       distinct_items,
       ROW_NUMBER() OVER (PARTITION BY p_promo_sk ORDER BY distinct_orders DESC) AS rn
   FROM agg
)
SELECT
   p_promo_sk,
   p_promo_name,
   distinct_orders,
   distinct_items
FROM ranked
WHERE rn <= 5
ORDER BY p_promo_sk, rn
LIMIT 100
