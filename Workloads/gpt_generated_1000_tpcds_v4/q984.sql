WITH base AS (
   SELECT
       d.d_year,
       d.d_month_seq,
       s.s_store_sk,
       s.s_store_name,
       ss.ss_ext_sales_price               AS store_sales_amount,
       ws.ws_ext_sales_price               AS web_sales_amount,
       cr.cr_return_amount                 AS catalog_return_amount,
       wr.wr_return_amt                    AS web_return_amount,
       inv.inv_quantity_on_hand,
       p.p_discount_active,
       r.r_reason_desc,
       w.w_warehouse_name,
       we.web_name,
       cd.cd_gender,
       ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY ss.ss_ext_sales_price DESC) AS store_sales_rank
   FROM   date_dim d
   LEFT JOIN store_sales ss      ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s            ON ss.ss_store_sk = s.s_store_sk
   LEFT JOIN promotion p        ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   LEFT JOIN web_sales ws       ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_returns wr    ON wr.wr_returned_date_sk = d.d_date_sk
   LEFT JOIN reason r           ON r.r_reason_sk = cr.cr_reason_sk
   LEFT JOIN warehouse w        ON w.w_warehouse_sk = cr.cr_warehouse_sk
   LEFT JOIN inventory inv      ON inv.inv_date_sk = d.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_site we        ON we.web_open_date_sk = d.d_date_sk
   LEFT JOIN customer c         ON c.c_first_sales_date_sk = d.d_date_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   WHERE  d.d_year = 2001
     AND  s.s_state = 'CA'
     AND  p.p_discount_active = 'Y'
     AND  cd.cd_gender = 'M'
)
SELECT
   d_year,
   d_month_seq,
   s_store_name,
   SUM(store_sales_amount)      AS total_store_sales,
   SUM(web_sales_amount)        AS total_web_sales,
   SUM(catalog_return_amount)   AS total_catalog_returns,
   SUM(web_return_amount)       AS total_web_returns,
   SUM(inv_quantity_on_hand)    AS total_inventory_on_hand,
   COUNT(*)                     AS txn_count,
   MAX(store_sales_rank)        AS max_sales_rank
FROM   base
GROUP BY d_year, d_month_seq, s_store_name
HAVING SUM(store_sales_amount) > 5000
   AND EXISTS (
        SELECT 1
        FROM   promotion p2
        WHERE  p2.p_discount_active = 'Y'
          AND  p2.p_start_date_sk > (
                 SELECT d_date_sk
                 FROM   date_dim
                 WHERE  d_year = 2000
                 LIMIT  1)
       )
ORDER BY total_store_sales DESC
LIMIT 100
