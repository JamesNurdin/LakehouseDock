WITH promo_common AS (
       SELECT p.p_promo_sk
       FROM promotion p
       WHERE p.p_purpose = 'Unknown'
       INTERSECT
       SELECT p2.p_promo_sk
       FROM promotion p2
       WHERE p2.p_channel_event = 'N'
   ),
   sales_data AS (
       SELECT
           ss.ss_ticket_number                                           AS ticket_number,
           ds.d_date                                                     AS sale_date,
           p.p_promo_id                                                  AS promo_id,
           ss.ss_ext_sales_price                                         AS amount,
           CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS flag,
           ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ss.ss_net_paid DESC) AS rank,
           (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_order_number = ss.ss_ticket_number) AS related_return_cnt
       FROM store_sales ss
       JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
       JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
       JOIN catalog_returns cr ON cr.cr_returned_date_sk = ds.d_date_sk
       WHERE ds.d_fy_year = 1910
         AND ds.d_month_seq BETWEEN 1200 AND 1300
         AND p.p_purpose = 'Unknown'
         AND p.p_channel_event = 'N'
         AND p.p_response_target = 1
         AND ss.ss_wholesale_cost > 20
         AND cr.cr_return_amount > 0
         AND p.p_promo_sk IN (SELECT p_promo_sk FROM promo_common)
   ),
   returns_data AS (
       SELECT
           cr.cr_order_number                                             AS ticket_number,
           dr.d_date                                                      AS sale_date,
           p.p_promo_id                                                   AS promo_id,
           cr.cr_return_amount                                            AS amount,
           CASE WHEN cr.cr_net_loss > 0 THEN 'Loss' ELSE 'Gain' END      AS flag,
           ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY cr.cr_return_amount DESC) AS rank,
           NULL                                                            AS related_return_cnt
       FROM catalog_returns cr
       JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
       JOIN promotion p ON p.p_start_date_sk = dr.d_date_sk
       WHERE dr.d_fy_year = 1910
         AND dr.d_month_seq BETWEEN 1200 AND 1300
         AND p.p_purpose = 'Unknown'
         AND p.p_channel_event = 'N'
         AND p.p_response_target = 1
         AND cr.cr_return_quantity > 0
   )
SELECT
    ticket_number,
    sale_date,
    promo_id,
    amount,
    flag,
    rank,
    related_return_cnt
FROM (
    SELECT ticket_number, sale_date, promo_id, amount, flag, rank, related_return_cnt
    FROM sales_data
    UNION DISTINCT
    SELECT ticket_number, sale_date, promo_id, amount, flag, rank, related_return_cnt
    FROM returns_data
) combined
ORDER BY amount DESC
LIMIT 100
