SELECT
    i.i_category,
    p.p_promo_name,
    hd_sales.hd_income_band_sk,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txns,
    SUM(ss.ss_net_paid) AS total_sales_net,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    AVG(wp.wp_image_count) AS avg_page_images,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN sr.sr_return_quantity ELSE 0 END) AS damaged_store_return_qty,
    SUM(CASE WHEN r_web.r_reason_desc = 'Damaged' THEN wr.wr_return_quantity ELSE 0 END) AS damaged_web_return_qty
FROM store_sales ss
JOIN time_dim t_sales
    ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer cs
    ON ss.ss_customer_sk = cs.c_customer_sk
JOIN household_demographics hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
    AND ss.ss_item_sk = sr.sr_item_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t_store_return
    ON sr.sr_return_time_sk = t_store_return.t_time_sk
JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
    AND cs.c_customer_sk = wr.wr_refunded_customer_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN time_dim t_web_return
    ON wr.wr_returned_time_sk = t_web_return.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE i.i_category IN ('Electronics', 'Books', 'Home')
  AND p.p_discount_active = 'Y'
GROUP BY
    i.i_category,
    p.p_promo_name,
    hd_sales.hd_income_band_sk
ORDER BY total_sales_net DESC
LIMIT 100
