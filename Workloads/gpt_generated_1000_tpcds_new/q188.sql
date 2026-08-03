WITH store_agg AS (
       SELECT ss_addr_sk,
              ss_promo_sk,
              SUM(ss_ext_sales_price) AS total_sales,
              COUNT(*)                AS sales_cnt
       FROM store_sales
       WHERE ss_ext_sales_price > 1000.00                    -- filter 1
         AND ss_quantity >= 2                                 -- filter 2
       GROUP BY ss_addr_sk, ss_promo_sk
     ),
     intersect_promos AS (
       SELECT ss_promo_sk AS promo_sk
       FROM store_sales
       WHERE ss_ext_sales_price > 2000.00
       INTERSECT
       SELECT ws_promo_sk
       FROM web_sales
       WHERE ws_net_paid_inc_ship_tax > 5000.00
     )
SELECT ca.ca_city,
       p.p_promo_name,
       sa.total_sales,
       sa.sales_cnt,
       ws.ws_net_paid_inc_ship_tax,
       CASE WHEN p.p_discount_active = 'Y'
            THEN sa.total_sales * 0.9
            ELSE sa.total_sales
       END AS adjusted_sales,
       RANK() OVER (PARTITION BY p.p_promo_name ORDER BY sa.total_sales DESC) AS sales_rank
FROM   store_agg sa
JOIN   intersect_promos ip ON sa.ss_promo_sk = ip.promo_sk
JOIN   customer_address ca ON sa.ss_addr_sk = ca.ca_address_sk                     -- allowed join
JOIN   promotion p ON sa.ss_promo_sk = p.p_promo_sk                                   -- allowed join
JOIN   web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk                         -- allowed join
                        AND ws.ws_promo_sk = p.p_promo_sk                           -- allowed join
WHERE  ws.ws_wholesale_cost < 80.00                                                -- filter 3
  AND  ws.ws_web_page_sk IN (271, 1154)                                            -- filter 4
  AND  ca.ca_state = 'CA'                                                          -- filter 5
ORDER BY sales_rank, adjusted_sales DESC
LIMIT 100
