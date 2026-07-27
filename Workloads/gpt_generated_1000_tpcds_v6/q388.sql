/*
Goal: Identify catalog departments with above‑average net loss on returned items whose description contains the word "Premium" and that were purchased by customers with an email domain of "example.com". The query uses regular‑expression filters, string concatenation, a scalar subquery for return‑quantity comparison, and a HAVING filter based on overall average net loss.
*/
WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_warehouse_sk,
        cr.cr_catalog_page_sk,
        i.i_item_desc,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        i.i_category,
        c.c_email_address,
        w.w_city,
        cp.cp_department,
        t.t_hour,
        t.t_meal_time
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium')
      AND regexp_like(c.c_email_address, '@example\\.com$')
      AND w.w_city LIKE 'A%'
)
SELECT
    fr.cp_department,
    fr.i_brand,
    fr.i_class,
    COUNT(*) AS num_returns,
    SUM(fr.cr_net_loss) AS total_net_loss,
    AVG(fr.cr_net_loss) AS avg_net_loss,
    CONCAT(fr.i_brand, ' - ', fr.i_class) AS brand_class,
    MAX(regexp_extract(fr.i_item_desc, '(\\d+)', 1)) AS extracted_number,
    MIN(fr.cr_returned_date_sk) AS earliest_return_date,
    MAX(fr.cr_returned_date_sk) AS latest_return_date
FROM filtered_returns fr
WHERE fr.cr_return_quantity > (
    SELECT AVG(cr2.cr_return_quantity)
    FROM catalog_returns cr2
)
GROUP BY fr.cp_department, fr.i_brand, fr.i_class
HAVING AVG(fr.cr_net_loss) > (
    SELECT AVG(cr3.cr_net_loss)
    FROM catalog_returns cr3
)
ORDER BY total_net_loss DESC
LIMIT 100
