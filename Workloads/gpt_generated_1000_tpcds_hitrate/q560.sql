WITH reason_cte AS (
        SELECT r_reason_sk,
               r_reason_desc
        FROM   reason
        WHERE  r_reason_desc LIKE '%size%'
    ),
    sales_filtered AS (
        SELECT ws.ws_order_number,
               ws.ws_quantity,
               ws.ws_net_paid,
               ws.ws_net_profit,
               ws.ws_sold_time_sk,
               ws.ws_item_sk,
               ws.ws_bill_customer_sk,
               ws.ws_web_page_sk,
               c.c_customer_id,
               i.i_item_id,
               t.t_hour,
               wp.wp_url
        FROM   web_sales ws
        JOIN   customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN   item i ON ws.ws_item_sk = i.i_item_sk
        JOIN   time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN   web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE  ws.ws_quantity > 20               -- predicate 1
          AND  ws.ws_net_profit > 0               -- predicate 2
          AND  t.t_hour BETWEEN 9 AND 17         -- predicate 3
    ),
    promo_set AS (
        SELECT ARRAY['PromoA','PromoB','PromoC'] AS promo_array
    )
SELECT
    sf.ws_order_number,
    sf.c_customer_id,
    sf.i_item_id,
    sf.t_hour,
    sf.wp_url,
    cr.cr_return_quantity,
    wr.wr_return_quantity,
    COALESCE(cr_r.r_reason_desc, wr_r.r_reason_desc) AS reason_description,
    ROW_NUMBER() OVER (PARTITION BY sf.c_customer_id ORDER BY sf.ws_net_paid DESC) AS rn_per_customer,
    RANK()        OVER (ORDER BY sf.ws_net_paid DESC)                     AS global_rank,
    promo_code
FROM   sales_filtered sf
FULL   OUTER JOIN web_returns wr
       ON sf.ws_order_number = wr.wr_order_number
LEFT   JOIN catalog_returns cr
       ON cr.cr_item_sk = sf.ws_item_sk
LEFT   JOIN reason cr_r
       ON cr.cr_reason_sk = cr_r.r_reason_sk
LEFT   JOIN reason wr_r
       ON wr.wr_reason_sk = wr_r.r_reason_sk
CROSS  JOIN promo_set ps
CROSS  JOIN UNNEST(ps.promo_array) AS t(promo_code)
WHERE  promo_code = 'PromoA'
ORDER  BY sf.ws_net_paid DESC
LIMIT  100
