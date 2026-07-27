WITH cs_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        SUM(cs.cs_quantity)    AS cs_total_qty,
        MIN(cs.cs_sold_date_sk) AS cs_min_date_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE td.t_shift = 'first'
      AND td.t_am_pm = 'PM'
      AND ca.ca_gmt_offset BETWEEN -9 AND -5
    GROUP BY cs.cs_item_sk
),
ws_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS ws_total_profit,
        SUM(ws.ws_quantity)   AS ws_total_qty,
        MIN(ws.ws_sold_date_sk) AS ws_min_date_sk,
        MIN(ws.ws_web_page_sk)   AS ws_web_page_sk
    FROM web_sales ws
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    WHERE td2.t_shift = 'first'
      AND td2.t_am_pm = 'PM'
      AND ca2.ca_gmt_offset BETWEEN -9 AND -5
    GROUP BY ws.ws_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    p.p_promo_name,
    inv.inv_quantity_on_hand,
    CASE WHEN i.i_color = 'Red' THEN 'Red Item' ELSE 'Other Color' END AS color_group,
    cs_agg.cs_total_profit,
    ws_agg.ws_total_profit,
    (cs_agg.cs_total_profit + ws_agg.ws_total_profit) AS total_net_profit,
    RANK() OVER (ORDER BY (cs_agg.cs_total_profit + ws_agg.ws_total_profit) DESC) AS profit_rank,
    (
        SELECT AVG(cs2.cs_total_profit + ws2.ws_total_profit)
        FROM (
            SELECT cs_item_sk, SUM(cs_net_profit) AS cs_total_profit
            FROM catalog_sales
            GROUP BY cs_item_sk
        ) cs2
        JOIN (
            SELECT ws_item_sk, SUM(ws_net_profit) AS ws_total_profit
            FROM web_sales
            GROUP BY ws_item_sk
        ) ws2 ON cs2.cs_item_sk = ws2.ws_item_sk
    ) AS avg_total_profit
FROM cs_agg
JOIN ws_agg ON cs_agg.cs_item_sk = ws_agg.ws_item_sk
JOIN item i ON cs_agg.cs_item_sk = i.i_item_sk
JOIN promotion p ON i.i_item_sk = p.p_item_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE i.i_current_price > 50
  AND p.p_discount_active = 'Y'
  AND inv.inv_quantity_on_hand > 200
ORDER BY total_net_profit DESC
LIMIT 100
