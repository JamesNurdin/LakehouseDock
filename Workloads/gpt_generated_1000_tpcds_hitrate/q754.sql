WITH base_agg AS (
    SELECT
        d_sales.d_year AS sales_year,
        ws.web_name,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        COUNT(DISTINCT sr.sr_return_quantity) AS distinct_return_qty,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN ss.ss_ext_discount_amt ELSE 0 END) AS promo_discount_sum
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d_sales.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_sales.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        d_sales.d_year BETWEEN 1999 AND 2001
        AND ws.web_state = 'CA'
        AND cc.cc_state = 'CA'
        AND cp.cp_type = 'Promotion'
        AND p.p_channel_tv = 'Y'
        AND ss.ss_quantity > 1
        AND ss.ss_sales_price > 20
    GROUP BY
        d_sales.d_year,
        ws.web_name,
        cc.cc_name,
        cp.cp_department,
        p.p_promo_name,
        r.r_reason_desc
),
ranked AS (
    SELECT
        ba.*,
        row_number() OVER (PARTITION BY ba.sales_year ORDER BY ba.total_net_paid DESC) AS rn
    FROM base_agg ba
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        WHERE p.p_promo_name = ba.p_promo_name
          AND sr.sr_return_quantity > 0
    )
)
SELECT
    sales_year,
    web_name,
    cc_name,
    cp_department,
    p_promo_name,
    r_reason_desc,
    total_net_paid,
    distinct_tickets,
    distinct_return_qty,
    promo_discount_sum,
    rn AS rank_within_year
FROM ranked
WHERE rn <= 3
ORDER BY sales_year, rn
