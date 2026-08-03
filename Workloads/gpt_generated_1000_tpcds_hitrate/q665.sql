WITH base AS (
   SELECT
       cr.cr_returned_date_sk,
       cr.cr_returned_time_sk,
       cr.cr_item_sk,
       cr.cr_warehouse_sk,
       cr.cr_reason_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       d.d_year,
       i.i_brand,
       i.i_category,
       w.w_state,
       r.r_reason_desc,
       s.s_state,
       ws.web_gmt_offset,
       (
         SELECT AVG(i2.i_current_price)
         FROM item i2
         WHERE i2.i_brand = i.i_brand
       ) AS avg_brand_price
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
   JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND w.w_state = 'CA'
     AND r.r_reason_desc = 'Defective'
     AND s.s_state = 'TX'
     AND ws.web_gmt_offset = -5.00
     AND cr.cr_return_amount > 500
),
discount_levels AS (
   SELECT 0 AS discount_pct UNION ALL SELECT 5 UNION ALL SELECT 10
)
SELECT
   bl.s_state,
   bl.w_state,
   bl.i_brand,
   bl.d_year,
   dl.discount_pct,
   SUM(bl.cr_net_loss) AS total_net_loss,
   COUNT(*) AS return_cnt,
   AVG(bl.cr_return_quantity) AS avg_return_qty,
   MAX(bl.avg_brand_price) AS max_avg_brand_price
FROM base bl
CROSS JOIN discount_levels dl
GROUP BY ROLLUP (bl.s_state, bl.w_state, bl.i_brand, bl.d_year, dl.discount_pct)
HAVING SUM(bl.cr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
