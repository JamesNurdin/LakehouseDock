WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        i.i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_sales,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS cnt_returns,
        COALESCE(r.r_reason_desc, 'No Return') AS sample_reason
    FROM store_sales ss
    INNER JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_store_sk = sr.sr_store_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_moy = 5
      AND i.i_formulation LIKE '%pink%'
      AND s.s_floor_space > 5000000
      AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
    GROUP BY s.s_store_name, d.d_year, i.i_category, r.r_reason_desc
)
SELECT
    s_store_name,
    d_year,
    i_category,
    total_sales,
    avg_discount,
    cnt_sales,
    total_returns,
    cnt_returns,
    sample_reason
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
