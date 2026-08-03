WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    cs.cs_order_number,
    cs.cs_net_profit,
    cs.cs_ext_sales_price,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    s.s_store_id,
    s.s_store_name,
    d_sold.d_date,
    t_sold.t_hour,
    ws.ws_web_site_sk,
    web_site.web_name,
    inv_agg.total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY cs.cs_net_profit DESC) AS rn_store_profit,
    LAG(cs.cs_net_profit) OVER (PARTITION BY s.s_store_id ORDER BY d_sold.d_date) AS prev_profit,
    (
        SELECT SUM(wr.wr_return_amt)
        FROM web_returns wr
        WHERE wr.wr_order_number = cs.cs_order_number
    ) AS total_return_amt
FROM catalog_sales cs
INNER JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
INNER JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
INNER JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
INNER JOIN inv_agg
        ON inv_agg.inv_item_sk = i.i_item_sk
       AND inv_agg.inv_date_sk = d_sold.d_date_sk
INNER JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
INNER JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_order_number = ws.ws_order_number
WHERE d_sold.d_year = 2001
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND s.s_state = 'CA'
  AND cs.cs_net_profit > 0
  AND cs.cs_item_sk IN (
        SELECT i2.i_item_sk
        FROM item i2
        WHERE i2.i_brand = 'Brand#45'
    )
ORDER BY cs.cs_net_profit DESC
LIMIT 100
