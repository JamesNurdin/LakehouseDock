WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_ticket_number,
        d.d_year,
        d.d_month_seq,
        d.d_dow,
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        p.p_promo_name,
        p.p_channel_demo,
        p.p_purpose
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN date_dim cd ON s.s_closed_date_sk = cd.d_date_sk
        AND cd.d_year = 2000  -- keep only stores closed in 2000 (null for stores still open)
    WHERE d.d_year = 2001
        AND d.d_dow = 2
        AND s.s_state = 'CA'
        AND s.s_tax_percentage > 6.00
        AND p.p_channel_demo = 'N'
        AND p.p_purpose = 'Unknown'
        AND ss.ss_quantity >= 2
        AND ss.ss_net_paid >= 500
)
SELECT
    sd.d_year,
    sd.d_month_seq,
    sd.s_store_name,
    sd.s_state,
    sd.p_promo_name,
    SUM(sd.ss_ext_sales_price)                     AS total_sales,
    SUM(sd.ss_quantity)                           AS total_units_sold,
    AVG(sd.ss_net_paid)                           AS avg_net_paid,
    MAX(sd.ss_ext_discount_amt)                   AS max_discount_amount,
    MIN(i.inv_quantity_on_hand)                   AS min_inventory_on_hand,
    COUNT(DISTINCT sd.ss_ticket_number)           AS distinct_tickets,
    COUNT(DISTINCT wp.wp_web_page_id)             AS distinct_web_pages
FROM sales_data sd
JOIN inventory i ON i.inv_date_sk = sd.ss_sold_date_sk
    AND i.inv_quantity_on_hand >= 100
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = sd.ss_sold_date_sk
    AND wp.wp_type = 'A'
GROUP BY
    sd.d_year,
    sd.d_month_seq,
    sd.s_store_name,
    sd.s_state,
    sd.p_promo_name
HAVING SUM(sd.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
