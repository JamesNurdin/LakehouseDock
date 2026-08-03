(
    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        COUNT(DISTINCT ss.ss_customer_sk)                                    AS distinct_customers,
        COUNT(DISTINCT i.i_item_id)                                           AS distinct_items,
        SUM(ss.ss_net_profit)                                                 AS total_profit,
        MAX(SUBSTRING(i.i_item_desc FROM 1 FOR 10))                          AS sample_desc,
        (SELECT MAX(d2.d_year) FROM tpcds.date_dim d2)                       AS max_year
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d            ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN tpcds.item i                ON ss.ss_item_sk        = i.i_item_sk
    LEFT JOIN tpcds.promotion p      ON ss.ss_promo_sk       = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{3}\\b')
      AND i.i_color LIKE 'R%'
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.store_returns sr
            WHERE sr.sr_ticket_number = ss.ss_ticket_number
        )
    GROUP BY CUBE (d.d_year, i.i_category, p.p_promo_name)
    HAVING COUNT(*) > 0

    UNION DISTINCT

    SELECT
        d.d_year,
        i.i_category,
        p.p_promo_name,
        COUNT(DISTINCT cs.cs_bill_customer_sk)                               AS distinct_customers,
        COUNT(DISTINCT i.i_item_id)                                           AS distinct_items,
        SUM(cs.cs_net_profit)                                                 AS total_profit,
        MAX(SUBSTRING(i.i_item_desc FROM 1 FOR 10))                          AS sample_desc,
        (SELECT MAX(d2.d_year) FROM tpcds.date_dim d2)                       AS max_year
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d            ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN tpcds.item i                ON cs.cs_item_sk        = i.i_item_sk
    LEFT JOIN tpcds.promotion p      ON cs.cs_promo_sk       = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{3}\\b')
      AND i.i_color LIKE 'R%'
      AND NOT EXISTS (
            SELECT 1
            FROM tpcds.catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        )
    GROUP BY CUBE (d.d_year, i.i_category, p.p_promo_name)
    HAVING COUNT(*) > 0
) 
ORDER BY d_year DESC, total_profit DESC 
LIMIT 100
