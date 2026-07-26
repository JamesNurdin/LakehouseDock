WITH top_discounted AS (
    SELECT ws.ws_order_number,
           wsit.web_site_id,
           sm.sm_type,
           td.t_shift,
           ws.ws_ext_discount_amt,
           ws.ws_ext_list_price,
           (ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_list_price,0)) AS discount_ratio,
           ROW_NUMBER() OVER (PARTITION BY wsit.web_site_id ORDER BY (ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_list_price,0)) DESC) AS rn,
           SUM(ws.ws_quantity) OVER (PARTITION BY wsit.web_site_id) AS total_qty_per_site
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_shift = 'Evening'
)
SELECT ws_order_number,
       web_site_id,
       sm_type,
       t_shift,
       ws_ext_discount_amt,
       ws_ext_list_price,
       discount_ratio,
       total_qty_per_site,
       rn
FROM top_discounted
WHERE rn <= 5
ORDER BY web_site_id, discount_ratio DESC
