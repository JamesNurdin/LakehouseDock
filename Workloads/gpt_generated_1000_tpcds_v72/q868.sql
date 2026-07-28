WITH base AS (
   SELECT
       i.i_category,
       d.d_year,
       cr.cr_return_amount,
       cr.cr_net_loss AS cr_net_loss,
       sr.sr_return_amt,
       sr.sr_net_loss,
       wr.wr_return_amt,
       wr.wr_net_loss,
       ss.ss_net_paid,
       inv.inv_quantity_on_hand,
       p.p_promo_id,
       sm.sm_carrier
   FROM tpcds.date_dim d
   JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
   JOIN tpcds.item i ON i.i_item_sk = cr.cr_item_sk
   JOIN tpcds.promotion p ON p.p_promo_sk = ss.ss_promo_sk
   JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
   JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
   JOIN tpcds.customer c ON c.c_customer_sk = cr.cr_refunded_customer_sk
   WHERE d.d_year = 2001
     AND p.p_channel_event = 'N'
     AND sm.sm_carrier = 'USPS'
     AND inv.inv_quantity_on_hand > 100
)

SELECT
    category,
    year,
    SUM(total_return_amount) AS total_return_amount,
    SUM(total_sales) AS total_sales,
    SUM(total_inventory) AS total_inventory,
    SUM(total_net_loss) AS total_net_loss,
    CASE WHEN SUM(total_sales) > 0 THEN SUM(total_return_amount) / SUM(total_sales) ELSE 0 END AS return_to_sales_ratio,
    CASE WHEN SUM(total_net_loss) > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS loss_flag,
    COUNT(DISTINCT promo_id) AS distinct_promotions
FROM (
    SELECT
        i_category AS category,
        d_year AS year,
        (cr_return_amount + sr_return_amt + wr_return_amt) AS total_return_amount,
        ss_net_paid AS total_sales,
        inv_quantity_on_hand AS total_inventory,
        (cr_net_loss + sr_net_loss + wr_net_loss) AS total_net_loss,
        p_promo_id AS promo_id
    FROM base
) t
GROUP BY ROLLUP (category, year)
HAVING SUM(total_return_amount) > 1000 OR SUM(total_sales) > 5000
ORDER BY category, year
