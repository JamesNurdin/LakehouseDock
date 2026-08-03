WITH
   item_promoted AS (
      SELECT i.i_item_sk
      FROM item i
      INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
   ),
   items_without_promo AS (
      SELECT i.i_item_sk
      FROM item i
      EXCEPT
      SELECT ip.i_item_sk FROM item_promoted ip
   ),
   base_join AS (
      SELECT
         cp.cp_catalog_page_sk,
         cp.cp_catalog_number,
         cp.cp_department,
         d_cr.d_year,
         d_cr.d_month_seq,
         i.i_item_sk,
         i.i_item_id,
         i.i_current_price,
         i.i_category,
         p.p_promo_sk,
         p.p_promo_name,
         p.p_discount_active,
         cr.cr_return_amount,
         cr.cr_return_quantity,
         c_ref.c_customer_sk AS refunded_cust_sk,
         c_ret.c_customer_sk AS returning_cust_sk,
         t_cr.t_hour AS cr_hour,
         sr.sr_return_amt,
         sr.sr_return_quantity,
         c_sr.c_customer_sk AS store_cust_sk,
         t_sr.t_hour AS sr_hour,
         wr.wr_return_amt,
         wr.wr_return_quantity,
         wp.wp_url,
         t_wr.t_hour AS wr_hour
      FROM catalog_returns cr
      JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
      JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
      JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
      JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
      JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
      JOIN customer c_ret
        ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
      JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
      JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
      JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
      JOIN customer c_sr
        ON sr.sr_customer_sk = c_sr.c_customer_sk
      JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
      JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
      JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
      JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
      WHERE d_cr.d_year = 2001
        AND i.i_current_price > 5.00
        AND p.p_discount_active = 'Y'
        AND cp.cp_catalog_page_sk IN (
            SELECT cr2.cr_catalog_page_sk
            FROM catalog_returns cr2
            WHERE cr2.cr_return_amount > 200
        )
        AND i.i_item_sk IN (SELECT i2.i_item_sk FROM items_without_promo i2)
   ),
   exploded_promos AS (
      SELECT bj.*, w.word
      FROM base_join bj
      CROSS JOIN UNNEST(split(bj.p_promo_name, ' ')) AS w(word)
   )
SELECT
   ep.cp_department,
   ep.cp_catalog_number,
   ep.i_item_id,
   ep.i_category,
   ep.i_current_price,
   ep.p_promo_name,
   ep.word AS promo_word,
   COUNT(*) AS cnt_returns,
   SUM(ep.cr_return_amount) AS total_return_amount,
   SUM(ep.sr_return_amt) AS total_store_return_amt,
   SUM(ep.wr_return_amt) AS total_web_return_amt,
   (
      SELECT SUM(sr3.sr_return_amt)
      FROM store_returns sr3
      WHERE sr3.sr_customer_sk = ep.refunded_cust_sk
   ) AS refunded_customer_store_return_total
FROM exploded_promos ep
GROUP BY
   ep.cp_department,
   ep.cp_catalog_number,
   ep.i_item_id,
   ep.i_category,
   ep.i_current_price,
   ep.p_promo_name,
   ep.word,
   ep.refunded_cust_sk
HAVING SUM(ep.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
