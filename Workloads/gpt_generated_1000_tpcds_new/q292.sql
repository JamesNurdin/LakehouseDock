WITH store_agg AS (
    SELECT
        COALESCE(d_sale.d_year, d_return.d_year) AS year,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(sr.sr_net_loss, 0)) AS total_amount,
        'store' AS source_type
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_sale
        ON ss.ss_sold_date_sk = d_sale.d_date_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_start_date_sk = d_sale.d_date_sk
          AND d_sale.d_year = 2001
    )
    GROUP BY COALESCE(d_sale.d_year, d_return.d_year)
),
catalog_agg AS (
    SELECT
        d.d_year AS year,
        SUM(cr.cr_return_amount) AS total_amount,
        'catalog' AS source_type
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_reason_sk IN (
        SELECT r.r_reason_sk
        FROM reason r
        WHERE r.r_reason_desc LIKE '%damaged%'
    )
    GROUP BY d.d_year
)
SELECT year, total_amount, source_type
FROM store_agg
UNION
SELECT year, total_amount, source_type
FROM catalog_agg
ORDER BY year DESC, total_amount DESC
LIMIT 100
